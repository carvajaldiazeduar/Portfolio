package com.portfolio.chatai.provider;

import com.portfolio.chatai.model.ChatRequest;
import com.portfolio.chatai.model.ChatResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class AzureChatProvider implements IChatProvider {

    private final RestTemplate restTemplate;
    private final ObjectMapper mapper;
    private final String endpoint;
    private final String apiKey;
    private final String deployment;

    public AzureChatProvider(ObjectMapper mapper, String endpoint, String apiKey,
                             String deployment, int timeoutMs) {
        this.mapper = mapper;
        this.endpoint = endpoint;
        this.apiKey = apiKey;
        this.deployment = deployment;
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(timeoutMs);
        factory.setReadTimeout(timeoutMs);
        this.restTemplate = new RestTemplate(factory);
    }

    @Override
    public ChatResponse completeChat(ChatRequest request) {
        String model = request.getModel() != null ? request.getModel()
                : System.getenv().getOrDefault("CHAT_MODEL", "gpt-4o-mini");
        Double temperature = request.getTemperature() != null
                ? request.getTemperature()
                : Double.parseDouble(System.getenv().getOrDefault("CHAT_TEMPERATURE", "0.7"));
        Integer maxTokens = request.getMax_tokens() != null
                ? request.getMax_tokens()
                : Integer.parseInt(System.getenv().getOrDefault("CHAT_MAX_TOKENS", "1024"));

        String apiVersion = System.getenv().getOrDefault("AZURE_OPENAI_API_VERSION", "2024-06-01-preview");
        String base = endpoint.endsWith("/") ? endpoint.substring(0, endpoint.length() - 1) : endpoint;
        String url = base + "/openai/deployments/" + deployment + "/chat/completions?api-version=" + apiVersion;

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("model", model);
        payload.put("messages", request.getMessages().stream()
                .map(m -> Map.of("role", m.getRole(), "content", m.getContent()))
                .toList());
        payload.put("temperature", temperature);
        payload.put("max_tokens", maxTokens);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("api-key", apiKey);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(url,
                    new HttpEntity<>(payload, headers), String.class);
            if (!response.getStatusCode().is2xxSuccessful()) {
                throw new RuntimeException("Provider error: HTTP " + response.getStatusCode().value());
            }
            ChatResponse resp = OpenAiCompatibleChatProvider.parseOpenAiResponse(mapper, response.getBody(), model);
            resp.setProvider("azure");
            return resp;
        } catch (RestClientException e) {
            throw new RuntimeException("Provider error: " + e.getMessage());
        }
    }
}
