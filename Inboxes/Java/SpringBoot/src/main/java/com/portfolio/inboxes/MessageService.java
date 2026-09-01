package com.portfolio.inboxes;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class MessageService {
    private final MessageRepository repository;
    private final CacheAdapter cache;
    private final ObjectMapper objectMapper;

    public MessageService(MessageRepository repository, CacheAdapter cache, ObjectMapper objectMapper) {
        this.repository = repository;
        this.cache = cache;
        this.objectMapper = objectMapper;
    }

    public List<Message> getAll() {
        String cached = cache.get("messages:all");
        if (cached != null) {
            return deserializeList(cached);
        }
        List<Message> list = repository.findAll().stream()
                .sorted((a, b) -> Long.compare(a.getId(), b.getId()))
                .toList();
        cache.set("messages:all", serialize(list));
        return list;
    }

    public Message create(String from, String subject, String body) {
        Message message = repository.save(new Message(from, subject, body));
        cache.delete("messages:all");
        return message;
    }

    public Message getById(Long id) {
        String cached = cache.get("message:" + id);
        if (cached != null) {
            Message msg = deserialize(cached);
            if (msg != null) {
                return msg;
            }
        }
        Optional<Message> message = repository.findById(id);
        if (message.isEmpty()) {
            return null;
        }
        Message msg = message.get();
        msg.setRead(true);
        repository.save(msg);
        cache.delete("messages:all");
        cache.set("message:" + id, serialize(msg));
        return msg;
    }

    public boolean delete(Long id) {
        Optional<Message> message = repository.findById(id);
        if (message.isEmpty()) {
            return false;
        }
        repository.delete(message.get());
        cache.delete("messages:all");
        cache.delete("message:" + id);
        return true;
    }

    private String serialize(List<Message> list) {
        try {
            return objectMapper.writeValueAsString(list);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private String serialize(Message message) {
        try {
            return objectMapper.writeValueAsString(message);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private List<Message> deserializeList(String json) {
        try {
            return objectMapper.readValue(json, new TypeReference<>() {
            });
        } catch (Exception e) {
            return List.of();
        }
    }

    private Message deserialize(String json) {
        try {
            return objectMapper.readValue(json, Message.class);
        } catch (Exception e) {
            return null;
        }
    }
}
