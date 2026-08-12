package com.portfolio.tasks;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class TaskService {
    private final TaskRepository repository;
    private final CacheAdapter cache;
    private final ObjectMapper objectMapper;

    public TaskService(TaskRepository repository, CacheAdapter cache, ObjectMapper objectMapper) {
        this.repository = repository;
        this.cache = cache;
        this.objectMapper = objectMapper;
    }

    public List<Task> getAll() {
        String cached = cache.get("tasks:all");
        if (cached != null) {
            return deserializeList(cached);
        }
        List<Task> list = repository.findAll().stream()
                .sorted((a, b) -> Long.compare(a.getId(), b.getId()))
                .toList();
        cache.set("tasks:all", serialize(list));
        return list;
    }

    public Optional<Task> getById(Long id) {
        return repository.findById(id);
    }

    public Task create(String title) {
        Task task = repository.save(new Task(title));
        cache.delete("tasks:all");
        return task;
    }

    public Optional<Task> update(Long id, String title, Boolean completed) {
        Optional<Task> existing = repository.findById(id);
        if (existing.isEmpty()) {
            return Optional.empty();
        }
        Task task = existing.get();
        if (title != null) {
            task.setTitle(title);
        }
        if (completed != null) {
            task.setCompleted(completed);
        }
        repository.save(task);
        cache.delete("tasks:all");
        return Optional.of(task);
    }

    public boolean delete(Long id) {
        Optional<Task> task = repository.findById(id);
        if (task.isEmpty()) {
            return false;
        }
        repository.delete(task.get());
        cache.delete("tasks:all");
        return true;
    }

    private String serialize(List<Task> list) {
        try {
            return objectMapper.writeValueAsString(list);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private List<Task> deserializeList(String json) {
        try {
            return objectMapper.readValue(json, new TypeReference<>() {
            });
        } catch (Exception e) {
            return List.of();
        }
    }
}
