package com.portfolio.inboxes;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/messages")
public class MessageController {
    private final MessageService service;

    public MessageController(MessageService service) {
        this.service = service;
    }

    @GetMapping
    public List<Message> list() {
        return service.getAll();
    }

    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody MessageInput input) {
        Message message = service.create(input.getFrom().trim(), input.getSubject().trim(), input.getBody().trim());
        return ResponseEntity.created(URI.create("/api/messages/" + message.getId())).body(message);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> get(@PathVariable Long id) {
        Message message = service.getById(id);
        if (message == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Not found"));
        }
        return ResponseEntity.ok(message);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        if (!service.delete(id)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Not found"));
        }
        return ResponseEntity.ok(Map.of("message", "Deleted"));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Map<String, String>>> onValidationError(
            MethodArgumentNotValidException ex) {
        Map<String, String> errors = new LinkedHashMap<>();
        for (var err : ex.getBindingResult().getFieldErrors()) {
            String msg = err.getDefaultMessage();
            if (msg != null && msg.endsWith("is required")) {
                errors.put(err.getField(), msg);
            } else {
                errors.putIfAbsent(err.getField(), msg);
            }
        }
        return ResponseEntity.badRequest().body(Map.of("errors", errors));
    }
}
