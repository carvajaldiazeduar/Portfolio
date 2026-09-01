package com.portfolio.eventprocessor.queue;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.DeliverCallback;
import com.rabbitmq.client.MessageProperties;

import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.BiConsumer;

public class RabbitMqQueueAdapter implements QueueAdapter {

    private final ConnectionFactory rabbit;
    private final ObjectMapper mapper = new ObjectMapper();
    private final AtomicBoolean running = new AtomicBoolean(false);
    private final List<Thread> threads = new java.util.ArrayList<>();

    public RabbitMqQueueAdapter(ConnectionFactory rabbit) {
        this.rabbit = rabbit;
    }

    @Override
    public void connect() {
    }

    @Override
    public void publish(String queue, Map<String, Object> message) {
        try (Connection connection = rabbit.newConnection(); Channel channel = connection.createChannel()) {
            channel.queueDeclare(queue, true, false, false, null);
            channel.basicPublish("", queue, MessageProperties.PERSISTENT_TEXT_PLAIN,
                    toJson(message).getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException("Failed to publish to RabbitMQ", e);
        }
    }

    @Override
    public void subscribe(String queue, BiConsumer<Map<String, Object>, String> handler) {
        running.set(true);
        Thread thread = new Thread(() -> {
            try (Connection connection = rabbit.newConnection(); Channel channel = connection.createChannel()) {
                channel.queueDeclare(queue, true, false, false, null);
                channel.basicQos(1);
                DeliverCallback deliver = (consumerTag, delivery) -> {
                    try {
                        String body = new String(delivery.getBody(), StandardCharsets.UTF_8);
                        handler.accept(fromJson(body), String.valueOf(delivery.getEnvelope().getDeliveryTag()));
                    } finally {
                        channel.basicAck(delivery.getEnvelope().getDeliveryTag(), false);
                    }
                };
                channel.basicConsume(queue, false, deliver, consumerTag -> {
                });
                while (running.get()) {
                    Thread.sleep(200);
                }
            } catch (Exception e) {
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                }
            }
        }, "consumer-" + queue);
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