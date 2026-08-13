package com.portfolio.chatai.provider;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

@Component
public class ChatProviderFactory {

    private final ObjectMapper mapper;

    public ChatProviderFactory(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    public String resolve(String requested) {
        if (requested != null && !requested.isBlank()) {
            return requested;
        }
        return System.getenv().getOrDefault("CHAT_PROVIDER", "openai");
    }

    public String fallbackProvider() {
        String fb = System.getenv("CHAT_FALLBACK_PROVIDER");
        return (fb != null && !fb.isBlank()) ? fb : null;
    }

    public int timeoutMs() {
        try {
            return Integer.parseInt(System.getenv().getOrDefault("CHAT_TIMEOUT_MS", "30000"));
        } catch (NumberFormatException e) {
            return 30000;
        }
    }

    public String keyFor(String provider) {
        return switch (provider) {
            case "openai", "openai-compatible" -> System.getenv("OPENAI_API_KEY");
            case "azure" -> System.getenv("AZURE_OPENAI_API_KEY");
            case "google" -> System.getenv("GOOGLE_API_KEY");
            case "anthropic" -> System.getenv("ANTHROPIC_API_KEY");
            default -> null;
        };
    }

    public String baseUrlFor(String provider) {
        return switch (provider) {
            case "openai", "openai-compatible" ->
                    System.getenv().getOrDefault("OPENAI_BASE_URL", "https://api.openai.com/v1");
            case "azure" ->
                    System.getenv().getOrDefault("AZURE_OPENAI_ENDPOINT", "https://api.openai.com/v1");
            case "google" ->
                    System.getenv().getOrDefault("GOOGLE_BASE_URL", "https://generativelanguage.googleapis.com");
            case "anthropic" ->
                    System.getenv().getOrDefault("ANTHROPIC_BASE_URL", "https://api.anthropic.com");
            default -> throw new IllegalArgumentException("Unsupported provider: " + provider);
        };
    }

    public String deploymentFor(String provider) {
        return switch (provider) {
            case "azure" -> System.getenv().getOrDefault("AZURE_OPENAI_DEPLOYMENT", "gpt-4o-mini");
            default -> null;
        };
    }

    public IChatProvider create(String provider) {
        provider = (provider == null || provider.isBlank()) ? resolve(null) : provider;
        String key = keyFor(provider);
        if (key == null || key.isBlank()) {
            throw new ProviderNotConfiguredException(provider);
        }
        String url = baseUrlFor(provider);
        int timeoutMs = timeoutMs();
        return switch (provider) {
            case "openai", "openai-compatible" ->
                    new OpenAiCompatibleChatProvider(mapper, url, key, timeoutMs);
            case "azure" ->
                    new AzureChatProvider(mapper, url, key, deploymentFor(provider), timeoutMs);
            case "google" ->
                    new GoogleChatProvider(mapper, url, key, timeoutMs);
            case "anthropic" ->
                    new AnthropicChatProvider(mapper, url, key, timeoutMs);
            default -> throw new IllegalArgumentException("Unsupported provider: " + provider);
        };
    }
}
