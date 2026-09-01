package com.portfolio.eventprocessor.queue;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;

import java.time.Duration;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.BiConsumer;

public class KafkaQueueAdapter implements QueueAdapter {

    private final KafkaProducer<String, String> producer;
    private final Map<String, Object> consumerProps;
    private final ObjectMapper mapper = new ObjectMapper();
    private final AtomicBoolean running = new AtomicBoolean(false);
    private final List<KafkaConsumer<String, String>> consumers = new java.util.ArrayList<>();

    public KafkaQueueAdapter(String brokers) {
        Map<String, Object> baseProps = new HashMap<>();
        baseProps.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, brokers);
        baseProps.put(ConsumerConfig.GROUP_ID_CONFIG, "eventprocessor-group");
        baseProps.put("client.id", "eventprocessor-client");

        Map<String, Object> producerProps = new HashMap<>(baseProps);
        producerProps.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        producerProps.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        producer = new KafkaProducer<>(producerProps);

        consumerProps = new HashMap<>();
        for (Map.Entry<String, Object> entry : baseProps.entrySet()) {
            consumerProps.put(entry.getKey(), String.valueOf(entry.getValue()));
        }
        consumerProps.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        consumerProps.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        consumerProps.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        consumerProps.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");
    }

    @Override
    public void connect() {
    }

    @Override
    public void publish(String queue, Map<String, Object> message) {
        try {
            producer.send(new ProducerRecord<>(queue, toJson(message))).get();
        } catch (Exception e) {
            throw new IllegalStateException("Failed to publish to Kafka", e);
        }
    }

    @Override
    public void subscribe(String queue, BiConsumer<Map<String, Object>, String> handler) {
        running.set(true);
        Thread thread = new Thread(() -> {
            try (KafkaConsumer<String, String> consumer = new KafkaConsumer<>(consumerProps)) {
                consumers.add(consumer);
                consumer.subscribe(List.of(queue));
                while (running.get()) {
                    try {
                        ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(500));
                        for (ConsumerRecord<String, String> record : records) {
                            handler.accept(fromJson(record.value()), record.partition() + "-" + record.offset());
                        }
                        if (!records.isEmpty()) {
                            consumer.commitAsync();
                        }
                    } catch (Exception e) {
                        try {
                            Thread.sleep(1000);
                        } catch (InterruptedException ie) {
                            Thread.currentThread().interrupt();
                            break;
                        }
                    }
                }
            } catch (Exception e) {
                Thread.currentThread().interrupt();
            }
        }, "consumer-" + queue);
        thread.setDaemon(true);
        thread.start();
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
        for (KafkaConsumer<String, String> consumer : consumers) {
            consumer.close(Duration.ofSeconds(1));
        }
        consumers.clear();
        producer.close(Duration.ofSeconds(1));
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