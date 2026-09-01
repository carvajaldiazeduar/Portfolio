package com.portfolio.passwordgenerator;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.net.URI;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class PasswordController {
    private final PasswordService service;

    public PasswordController(PasswordService service) {
        this.service = service;
    }

    @GetMapping("/generate")
    public ResponseEntity<?> generate(
            @RequestParam(defaultValue = "16") int length,
            @RequestParam(defaultValue = "true") boolean uppercase,
            @RequestParam(defaultValue = "true") boolean lowercase,
            @RequestParam(defaultValue = "true") boolean numbers,
            @RequestParam(defaultValue = "false") boolean symbols) {
        try {
            String password = service.generate(length, uppercase, lowercase, numbers, symbols);
            return ResponseEntity.ok(Map.of("password", password));
        } catch (IllegalArgumentException e) {
            Map<String, String> errors = new LinkedHashMap<>();
            if (e.getMessage().startsWith("Password length must be at least")) {
                errors.put("length", e.getMessage());
            } else {
                errors.put("flags", e.getMessage());
            }
            return ResponseEntity.badRequest().body(Map.of("errors", errors));
        }
    }

    @GetMapping("/passwords")
    public List<StoredPassword> list() {
        return service.getAll();
    }

    @PostMapping("/passwords")
    public ResponseEntity<?> create(@Valid @RequestBody StoredPasswordInput input) {
        StoredPassword stored = service.create(input.getPassword().trim());
        return ResponseEntity.created(URI.create("/api/passwords/" + stored.getId())).body(stored);
    }

    @DeleteMapping("/passwords/{id}")
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
