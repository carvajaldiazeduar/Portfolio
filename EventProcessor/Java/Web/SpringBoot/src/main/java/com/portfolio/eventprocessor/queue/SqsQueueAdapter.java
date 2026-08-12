package com.portfolio.eventprocessor.queue;

public class SqsQueueAdapter implements QueueAdapter {
    @Override
    public void connect() {
    }

    @Override
    public void publish(String queue, java.util.Map<String, Object> message) {
        throw new UnsupportedOperationException("SQS not configured");
    }

    @Override
    public void subscribe(String queue, java.util.function.BiConsumer<java.util.Map<String, Object>, String> handler) {
    }

    @Override
    public void ack(String messageId) {
    }

    @Override
    public void nack(String messageId, boolean requeue) {
    }

    @Override
    public void close() {
    }
}
