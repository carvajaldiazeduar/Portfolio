package com.portfolio.chatai.provider;

import com.portfolio.chatai.model.ChatChoice;
import com.portfolio.chatai.model.ChatRequest;
import com.portfolio.chatai.model.ChatResponse;
import com.portfolio.chatai.model.ChatUsage;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class AnthropicChatProvider implements IChatProvider {

    private final RestTemplate restTemplate;
    private final ObjectMapper mapper;
    private final String baseUrl;
    private final String apiKey;

    public AnthropicChatProvider(ObjectMapper mapper, String baseUrl, String apiKey, int timeoutMs) {
        this.mapper = mapper;
        this.baseUrl = baseUrl;
        this.apiKey = apiKey;
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

        List<Map<String, Object>> messages = new ArrayList<>();
        String system = null;
        for (var m : request.getMessages()) {
            if ("system".equalsIgnoreCase(m.getRole())) {
                system = m.getContent();
                continue;
            }
            String role = "assistant".equalsIgnoreCase(m.getRole()) ? "assistant" : "user";
            Map<String, Object> msg = new LinkedHashMap<>();
            msg.put("role", role);
            msg.put("content", m.getContent());
            messages.add(msg);
        }

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("model", model);
        if (system != null && !system.isBlank()) {
            payload.put("system", system);
        }
        payload.put("messages", messages);
        payload.put("max_tokens", maxTokens);
        payload.put("temperature", temperature);

        String base = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        String url = base + "/v1/messages";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("x-api-key", apiKey);
        headers.set("anthropic-version", "2023-06-01");

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(url,
                    new HttpEntity<>(payload, headers), String.class);
            if (!response.getStatusCode().is2xxSuccessful()) {
                throw new RuntimeException("Provider error: HTTP " + response.getStatusCode().value());
            }
            return parseAnthropicResponse(response.getBody(), model);
        } catch (RestClientException e) {
            throw new RuntimeException("Provider error: " + e.getMessage());
        }
    }

    @SuppressWarnings("unchecked")
    private ChatResponse parseAnthropicResponse(String body, String model) {
        ChatResponse resp = new ChatResponse();
        resp.setModel(model);
        resp.setProvider("anthropic");
        try {
            Map<String, Object> data = mapper.readValue(body, Map.class);
            List<Map<String, Object>> content = (List<Map<String, Object>>) data.getOrDefault("content", List.of());
            String text = "";
            for (Map<String, Object> c : content) {
                if ("text".equals(c.get("type"))) {
                    text += (String) c.getOrDefault("text", "");
                }
            }
            ChatChoice choice = new ChatChoice();
            choice.setRole("assistant");
            choice.setContent(text);
            resp.setChoices(List.of(choice));
            Map<String, Object> usageMap = (Map<String, Object>) data.getOrDefault("usage", Map.of());
            int in = ((Number) usageMap.getOrDefault("input_tokens", 0)).intValue();
            int out = ((Number) usageMap.getOrDefault("output_tokens", 0)).intValue();
            ChatUsage usage = new ChatUsage();
            usage.setPrompt_tokens(in);
            usage.setCompletion_tokens(out);
            usage.setTotal_tokens(in + out);
            resp.setUsage(usage);
        } catch (Exception e) {
            resp.setChoices(List.of(emptyChoice()));
            resp.setUsage(new ChatUsage());
        }
        return resp;
    }

    private static ChatChoice emptyChoice() {
        ChatChoice choice = new ChatChoice();
        choice.setRole("assistant");
        choice.setContent("");
        return choice;
    }
}
