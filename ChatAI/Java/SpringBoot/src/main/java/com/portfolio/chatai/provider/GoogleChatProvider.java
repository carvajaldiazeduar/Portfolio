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

public class GoogleChatProvider implements IChatProvider {

    private final RestTemplate restTemplate;
    private final ObjectMapper mapper;
    private final String baseUrl;
    private final String apiKey;

    public GoogleChatProvider(ObjectMapper mapper, String baseUrl, String apiKey, int timeoutMs) {
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

        List<Map<String, Object>> contents = new ArrayList<>();
        for (var m : request.getMessages()) {
            String role = "user".equalsIgnoreCase(m.getRole()) ? "user"
                    : "assistant".equalsIgnoreCase(m.getRole()) ? "model" : "user";
            Map<String, Object> c = new LinkedHashMap<>();
            c.put("role", role);
            c.put("parts", List.of(Map.of("text", m.getContent())));
            contents.add(c);
        }

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("contents", contents);
        Map<String, Object> genConfig = new LinkedHashMap<>();
        genConfig.put("temperature", temperature);
        genConfig.put("maxOutputTokens", maxTokens);
        payload.put("generationConfig", genConfig);

        String base = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        String url = base + "/v1beta/models/" + model + ":generateContent?key=" + apiKey;

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(url,
                    new HttpEntity<>(payload, headers), String.class);
            if (!response.getStatusCode().is2xxSuccessful()) {
                throw new RuntimeException("Provider error: HTTP " + response.getStatusCode().value());
            }
            return parseGoogleResponse(response.getBody(), model);
        } catch (RestClientException e) {
            throw new RuntimeException("Provider error: " + e.getMessage());
        }
    }

    @SuppressWarnings("unchecked")
    private ChatResponse parseGoogleResponse(String body, String model) {
        ChatResponse resp = new ChatResponse();
        resp.setModel(model);
        resp.setProvider("google");
        try {
            Map<String, Object> data = mapper.readValue(body, Map.class);
            List<Map<String, Object>> candidates =
                    (List<Map<String, Object>>) data.getOrDefault("candidates", List.of());
            List<ChatChoice> out = new ArrayList<>();
            for (Map<String, Object> c : candidates) {
                Map<String, Object> content = (Map<String, Object>) c.get("content");
                if (content != null) {
                    List<Map<String, Object>> parts = (List<Map<String, Object>>) content.get("parts");
                    if (parts != null) {
                        ChatChoice choice = new ChatChoice();
                        choice.setRole((String) content.getOrDefault("role", "model"));
                        String text = "";
                        for (Map<String, Object> p : parts) {
                            text += (String) p.getOrDefault("text", "");
                        }
                        choice.setContent(text);
                        out.add(choice);
                    }
                }
            }
            if (out.isEmpty()) {
                ChatChoice empty = new ChatChoice();
                empty.setRole("assistant");
                empty.setContent("");
                out.add(empty);
            }
            resp.setChoices(out);
            Map<String, Object> usageMap = (Map<String, Object>) data.getOrDefault("usageMetadata", Map.of());
            ChatUsage usage = new ChatUsage();
            usage.setPrompt_tokens(((Number) usageMap.getOrDefault("promptTokens", 0)).intValue());
            usage.setCompletion_tokens(((Number) usageMap.getOrDefault("candidatesTokens", 0)).intValue());
            usage.setTotal_tokens(((Number) usageMap.getOrDefault("totalTokens", 0)).intValue());
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
