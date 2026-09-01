package com.portfolio.chatai;

import com.portfolio.chatai.model.ChatRequest;
import com.portfolio.chatai.model.ChatResponse;
import com.portfolio.chatai.model.Message;
import com.portfolio.chatai.provider.ChatProviderFactory;
import com.portfolio.chatai.provider.ProviderNotConfiguredException;
import com.portfolio.chatai.provider.IChatProvider;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

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

        if (factory.ragEnabled()) {
            List<Message> messages = request.getMessages();
            Message lastUser = null;
            for (int i = messages.size() - 1; i >= 0; i--) {
                if ("user".equals(messages.get(i).getRole())) {
                    lastUser = messages.get(i);
                    break;
                }
            }
            if (lastUser != null) {
                String query = lastUser.getContent() == null ? "" : lastUser.getContent();
                List<String> documents = factory.retrieveContext(query);
                if (!documents.isEmpty()) {
                    String context = "Use the following context to answer the user's question:\n\n"
                            + documents.stream().map(d -> "- " + d).collect(Collectors.joining("\n"));
                    Message system = new Message();
                    system.setRole("system");
                    system.setContent(context);
                    request.getMessages().add(0, system);
                }
            }
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
