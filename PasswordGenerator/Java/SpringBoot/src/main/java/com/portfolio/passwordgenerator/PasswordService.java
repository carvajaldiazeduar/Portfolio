package com.portfolio.passwordgenerator;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class PasswordService {
    private final StoredPasswordRepository repository;
    private final CacheAdapter cache;
    private final ObjectMapper objectMapper;

    public PasswordService(StoredPasswordRepository repository, CacheAdapter cache, ObjectMapper objectMapper) {
        this.repository = repository;
        this.cache = cache;
        this.objectMapper = objectMapper;
    }

    public String generate(int length, boolean useUpper, boolean useLower, boolean useDigits, boolean useSymbols) {
        return PasswordGenerator.generate(length, useUpper, useLower, useDigits, useSymbols);
    }

    public List<StoredPassword> getAll() {
        String cached = cache.get("passwords:all");
        if (cached != null) {
            return deserializeList(cached);
        }
        List<StoredPassword> list = repository.findAll().stream()
                .sorted((a, b) -> Long.compare(a.getId(), b.getId()))
                .toList();
        cache.set("passwords:all", serialize(list));
        return list;
    }

    public StoredPassword create(String password) {
        StoredPassword stored = repository.save(new StoredPassword(password));
        cache.delete("passwords:all");
        return stored;
    }

    public boolean delete(Long id) {
        Optional<StoredPassword> entry = repository.findById(id);
        if (entry.isEmpty()) {
            return false;
        }
        repository.delete(entry.get());
        cache.delete("passwords:all");
        return true;
    }

    private String serialize(List<StoredPassword> list) {
        try {
            return objectMapper.writeValueAsString(list);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private List<StoredPassword> deserializeList(String json) {
        try {
            return objectMapper.readValue(json, new TypeReference<>() {
            });
        } catch (Exception e) {
            return List.of();
        }
    }
}
