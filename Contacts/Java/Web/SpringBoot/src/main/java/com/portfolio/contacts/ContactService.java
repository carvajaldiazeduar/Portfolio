package com.portfolio.contacts;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;
import java.util.Optional;

@Service
public class ContactService {
    private final ContactRepository repository;
    private final CacheAdapter cache;
    private final ObjectMapper objectMapper;

    public ContactService(ContactRepository repository, CacheAdapter cache, ObjectMapper objectMapper) {
        this.repository = repository;
        this.cache = cache;
        this.objectMapper = objectMapper;
    }

    public List<Contact> getAll() {
        String cached = cache.get("contacts:all");
        if (cached != null) {
            return deserializeList(cached);
        }
        List<Contact> list = repository.findAll().stream()
                .sorted((a, b) -> Long.compare(a.getId(), b.getId()))
                .toList();
        cache.set("contacts:all", serialize(list));
        return list;
    }

    public Contact create(String name, String phone, String email) {
        Contact contact = repository.save(new Contact(name, phone, email));
        cache.delete("contacts:all");
        return contact;
    }

    public List<Contact> search(String query) {
        String key = "contacts:search:" + query;
        String cached = cache.get(key);
        if (cached != null) {
            return deserializeList(cached);
        }
        String q = query.toLowerCase(Locale.ROOT);
        List<Contact> list = repository.findAll().stream()
                .filter(c -> c.getName().toLowerCase(Locale.ROOT).contains(q))
                .sorted((a, b) -> Long.compare(a.getId(), b.getId()))
                .toList();
        cache.set(key, serialize(list));
        return list;
    }

    public boolean delete(Long id) {
        Optional<Contact> contact = repository.findById(id);
        if (contact.isEmpty()) {
            return false;
        }
        repository.delete(contact.get());
        cache.delete("contacts:all");
        return true;
    }

    private String serialize(List<Contact> list) {
        try {
            return objectMapper.writeValueAsString(list);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private List<Contact> deserializeList(String json) {
        try {
            return objectMapper.readValue(json, new TypeReference<>() {
            });
        } catch (Exception e) {
            return List.of();
        }
    }
}
