package com.portfolio.chatai;

import com.portfolio.chatai.model.ChatRequest;
import com.portfolio.chatai.model.ChatResponse;
import com.portfolio.chatai.provider.ChatProviderFactory;
import com.portfolio.chatai.provider.ProviderNotConfiguredException;
import com.portfolio.chatai.provider.IChatProvider;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("")
public class ChatController {

    private final ChatProviderFactory factory;

    public ChatController(ChatProviderFactory factory) {
        this.factory = factory;
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "ok");
    }

    @PostMapping("/api/chat")
    public ResponseEntity<?> chat(@RequestBody ChatRequest request) {
        if (request.getMessages() == null || request.getMessages().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Messages must not be empty"));
        }

        String provider = factory.resolve(request.getProvider());

        IChatProvider primary;
        try {
            primary = factory.create(provider);
        } catch (ProviderNotConfiguredException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }

        try {
            ChatResponse response = primary.completeChat(request);
            response.setProvider(provider);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            String fallback = factory.fallbackProvider();
            if (fallback != null && !fallback.isBlank()) {
                try {
                    IChatProvider fbProvider = factory.create(fallback);
                    ChatResponse response = fbProvider.completeChat(request);
                    response.setProvider(fallback);
                    return ResponseEntity.ok(response);
                } catch (ProviderNotConfiguredException | IllegalArgumentException ex) {
                    // fallback not configured -> fall through to 502
                } catch (Exception ex) {
                    // fallback also failed -> fall through to 502
                }
            }
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(Map.of("error", e.getMessage()));
        }
    }
}
