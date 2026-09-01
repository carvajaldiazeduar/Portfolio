package com.portfolio.eventprocessor.queue;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.BiConsumer;
import java.util.function.Consumer;

public class InMemoryQueueAdapter implements QueueAdapter {
    private final Map<String, ConcurrentLinkedQueue<Envelope>> queues = new ConcurrentHashMap<>();
    private volatile boolean running = false;

    public record Envelope(String id, Map<String, Object> data) {
    }

    @Override
    public void connect() {
    }

    @Override
    public void publish(String queue, Map<String, Object> message) {
        queues.computeIfAbsent(queue, k -> new ConcurrentLinkedQueue<>())
                .add(new Envelope(Thread.currentThread().getName() + "-" + System.nanoTime(), message));
    }

    @Override
    public void subscribe(String queue, BiConsumer<Map<String, Object>, String> handler) {
        running = true;
        new Thread(() -> {
            ConcurrentLinkedQueue<Envelope> q = queues.computeIfAbsent(queue, k -> new ConcurrentLinkedQueue<>());
            while (running) {
                Envelope env = q.poll();
                if (env != null) {
                    try {
                        handler.accept(env.data(), env.id());
                    } catch (Exception e) {
                        // ignore
                    }
                } else {
                    try {
                        Thread.sleep(50);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
            }
        }).start();
    }

    @Override
    public void ack(String messageId) {
    }

    @Override
    public void nack(String messageId, boolean requeue) {
    }

    @Override
    public void close() {
        running = false;
    }
}
