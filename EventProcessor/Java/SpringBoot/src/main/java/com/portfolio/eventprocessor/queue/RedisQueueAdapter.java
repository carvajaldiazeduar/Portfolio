package com.portfolio.eventprocessor.queue;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.BiConsumer;

public class RedisQueueAdapter implements QueueAdapter {

    private final StringRedisTemplate redis;
    private final ObjectMapper mapper = new ObjectMapper();
    private final AtomicBoolean running = new AtomicBoolean(false);
    private final List<Thread> threads = new ArrayList<>();

    public RedisQueueAdapter(StringRedisTemplate redis) {
        this.redis = redis;
    }

    @Override
    public void connect() {
    }

    @Override
    public void publish(String queue, Map<String, Object> message) {
        redis.opsForList().rightPush(queue, toJson(message));
    }

    @Override
    public void subscribe(String queue, BiConsumer<Map<String, Object>, String> handler) {
        running.set(true);
        Thread thread = new Thread(() -> {
            while (running.get()) {
                try {
                    String raw = redis.opsForList().leftPop(queue, Duration.ofSeconds(1));
                    if (raw != null) {
                        Map<String, Object> data = fromJson(raw);
                        handler.accept(data, Thread.currentThread().getName() + "-" + System.nanoTime());
                    }
                } catch (Exception e) {
                    try {
                        Thread.sleep(500);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        return;
                    }
                }
            }
        });
        thread.setDaemon(true);
        thread.start();
        threads.add(thread);
    }

    @Override
    public void ack(String messageId) {
    }

    @Override
    public void nack(String messageId, boolean requeue) {
    }

    @Override
    public void close() {
        running.set(false);
        for (Thread thread : threads) {
            thread.interrupt();
        }
        threads.clear();
    }

    private String toJson(Map<String, Object> message) {
        try {
            return mapper.writeValueAsString(message);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to serialize message", e);
        }
    }

    private Map<String, Object> fromJson(String raw) {
        try {
            return mapper.readValue(raw, new TypeReference<LinkedHashMap<String, Object>>() {
            });
        } catch (Exception e) {
            throw new IllegalStateException("Failed to deserialize message", e);
        }
    }
}