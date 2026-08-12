package com.portfolio.tasks;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.net.URI;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/tasks")
public class TaskController {
    private final TaskService service;

    public TaskController(TaskService service) {
        this.service = service;
    }

    @GetMapping
    public List<Task> list() {
        return service.getAll();
    }

    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody TaskInput input) {
        Task task = service.create(input.getTitle().trim());
        return ResponseEntity.created(URI.create("/api/tasks/" + task.getId())).body(task);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getOne(@PathVariable Long id) {
        Optional<Task> task = service.getById(id);
        if (task.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Not found"));
        }
        return ResponseEntity.ok(task.get());
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody TaskUpdateInput input) {
        if ((input.getTitle() == null && input.getCompleted() == null)
                || (input.getTitle() != null && input.getTitle().trim().isEmpty())) {
            return ResponseEntity.badRequest().body(Map.of("errors", Map.of("title", "Title is required")));
        }
        Optional<Task> updated = service.update(id, input.getTitle() == null ? null : input.getTitle().trim(),
                input.getCompleted());
        if (updated.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Not found"));
        }
        return ResponseEntity.ok(updated.get());
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
