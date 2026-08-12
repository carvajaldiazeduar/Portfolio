package com.portfolio.chatai.provider;

import com.portfolio.chatai.model.ChatChoice;
import com.portfolio.chatai.model.ChatRequest;
import com.portfolio.chatai.model.ChatResponse;
import com.portfolio.chatai.model.ChatUsage;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class OpenAiCompatibleChatProvider implements IChatProvider {

    private final RestTemplate restTemplate;
    private final ObjectMapper mapper;
    private final String baseUrl;
    private final String apiKey;

    @Autowired
    public OpenAiCompatibleChatProvider(RestTemplate restTemplate, ObjectMapper mapper) {
        this.restTemplate = restTemplate;
        this.mapper = mapper;
        this.baseUrl = System.getenv().getOrDefault("OPENAI_BASE_URL", "https://api.openai.com/v1");
        this.apiKey = System.getenv().getOrDefault("OPENAI_API_KEY", "");
    }

    @Override
    public ChatResponse completeChat(ChatRequest request) {
        String model = request.getModel() != null ? request.getModel() : System.getenv().getOrDefault("CHAT_MODEL", "gpt-4o-mini");
        Double temperature = request.getTemperature() != null ? request.getTemperature() : Double.parseDouble(System.getenv().getOrDefault("CHAT_TEMPERATURE", "0.7"));
        Integer maxTokens = request.getMax_tokens() != null ? request.getMax_tokens() : Integer.parseInt(System.getenv().getOrDefault("CHAT_MAX_TOKENS", "1024"));

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("model", model);
        List<Map<String, String>> messages = request.getMessages().stream()
                .map(m -> Map.of("role", m.getRole(), "content", m.getContent()))
                .toList();
        payload.put("messages", messages);
        payload.put("temperature", temperature);
        payload.put("max_tokens", maxTokens);

        String url = baseUrl.endsWith("/") ? baseUrl + "chat/completions" : baseUrl + "/chat/completions";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        if (apiKey != null && !apiKey.isEmpty()) {
            headers.setBearerAuth(apiKey);
        }

        ResponseEntity<String> response;
        try {
            response = restTemplate.postForEntity(url, new HttpEntity<>(payload, headers), String.class);
        } catch (RestClientException e) {
            throw new RuntimeException("Provider error: " + e.getMessage());
        }

        return parseChatResponse(response.getBody(), model);
    }

    @SuppressWarnings("unchecked")
    private ChatResponse parseChatResponse(String body, String model) {
        ChatResponse resp = new ChatResponse();
        resp.setModel(model);
        if (body == null || body.isEmpty()) {
            resp.setId("");
            resp.setChoices(List.of(emptyChoice()));
            resp.setUsage(new ChatUsage());
            return resp;
        }
        try {
            Map<String, Object> data = mapper.readValue(body, Map.class);
            resp.setId((String) data.getOrDefault("id", ""));
            List<Map<String, Object>> choices = (List<Map<String, Object>>) data.getOrDefault("choices", List.of());
            List<ChatChoice> out = new ArrayList<>();
            for (Map<String, Object> c : choices) {
                Object msgObj = c.get("message");
                if (msgObj instanceof Map) {
                    Map<String, Object> msg = (Map<String, Object>) msgObj;
                    ChatChoice choice = new ChatChoice();
                    choice.setRole((String) msg.getOrDefault("role", "assistant"));
                    choice.setContent((String) msg.getOrDefault("content", ""));
                    out.add(choice);
                }
            }
            if (out.isEmpty()) {
                out.add(emptyChoice());
            }
            resp.setChoices(out);
            Map<String, Object> usageMap = (Map<String, Object>) data.getOrDefault("usage", Map.of());
            ChatUsage usage = new ChatUsage();
            usage.setPrompt_tokens(((Number) usageMap.getOrDefault("prompt_tokens", 0)).intValue());
            usage.setCompletion_tokens(((Number) usageMap.getOrDefault("completion_tokens", 0)).intValue());
            usage.setTotal_tokens(((Number) usageMap.getOrDefault("total_tokens", 0)).intValue());
            resp.setUsage(usage);
        } catch (Exception e) {
            resp.setId("");
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
