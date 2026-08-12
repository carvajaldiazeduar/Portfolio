package com.portfolio.chatai;

import com.portfolio.chatai.model.ChatRequest;
import com.portfolio.chatai.model.ChatResponse;
import com.portfolio.chatai.provider.IChatProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("")
public class ChatController {

    private final IChatProvider provider;

    @Autowired
    public ChatController(IChatProvider provider) {
        this.provider = provider;
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
        try {
            ChatResponse response = provider.completeChat(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(Map.of("error", e.getMessage()));
        }
    }
}
