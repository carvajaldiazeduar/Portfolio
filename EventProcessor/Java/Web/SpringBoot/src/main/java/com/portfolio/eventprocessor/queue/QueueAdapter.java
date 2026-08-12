package com.portfolio.eventprocessor.queue;

import java.util.Map;
import java.util.function.BiConsumer;

public interface QueueAdapter {
    void connect();
    void publish(String queue, Map<String, Object> message);
    void subscribe(String queue, BiConsumer<Map<String, Object>, String> handler);
    void ack(String messageId);
    void nack(String messageId, boolean requeue);
    void close();
}
