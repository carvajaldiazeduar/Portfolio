package com.portfolio.contacts;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/contacts")
public class ContactController {
    private final ContactService service;

    public ContactController(ContactService service) {
        this.service = service;
    }

    @GetMapping
    public List<Contact> list() {
        return service.getAll();
    }

    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody ContactInput input) {
        Contact contact = service.create(input.getName().trim(), input.getPhone().trim(), input.getEmail().trim());
        return ResponseEntity.created(URI.create("/api/contacts/" + contact.getId())).body(contact);
    }

    @GetMapping("/search")
    public List<Contact> search(@RequestParam(defaultValue = "") String q) {
        return service.search(q.toLowerCase());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        if (!service.delete(id)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Not found"));
        }
        return ResponseEntity.ok(Map.of("message", "Deleted"));
    }

    @org.springframework.web.bind.annotation.ExceptionHandler(org.springframework.web.bind.MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Map<String, String>>> onValidationError(
            org.springframework.web.bind.MethodArgumentNotValidException ex) {
        Map<String, String> errors = new LinkedHashMap<>();
        for (var err : ex.getBindingResult().getFieldErrors()) {
            String msg = err.getDefaultMessage();
            if (msg != null && (msg.endsWith("is required") || msg.equals("Invalid email format"))) {
                errors.put(err.getField(), msg);
            } else {
                errors.putIfAbsent(err.getField(), msg);
            }
        }
        return ResponseEntity.badRequest().body(Map.of("errors", errors));
    }
}
