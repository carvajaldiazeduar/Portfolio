package com.portfolio.eventprocessor.queue;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.CreateQueueRequest;
import software.amazon.awssdk.services.sqs.model.CreateQueueResponse;
import software.amazon.awssdk.services.sqs.model.DeleteMessageRequest;
import software.amazon.awssdk.services.sqs.model.GetQueueUrlRequest;
import software.amazon.awssdk.services.sqs.model.GetQueueUrlResponse;
import software.amazon.awssdk.services.sqs.model.Message;
import software.amazon.awssdk.services.sqs.model.QueueDoesNotExistException;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageRequest;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageResponse;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.BiConsumer;

public class SqsQueueAdapter implements QueueAdapter {

    private final SqsClient sqs;
    private final ObjectMapper mapper = new ObjectMapper();
    private final Map<String, String> queueUrls = new ConcurrentHashMap<>();
    private final AtomicBoolean running = new AtomicBoolean(false);
    private final List<Thread> threads = new java.util.ArrayList<>();

    public SqsQueueAdapter(SqsClient sqs) {
        this.sqs = sqs;
    }

    @Override
    public void connect() {
    }

    @Override
    public void publish(String queue, Map<String, Object> message) {
        sqs.sendMessage(SendMessageRequest.builder()
                .queueUrl(ensure(queue))
                .messageBody(toJson(message))
                .build());
    }

    @Override
    public void subscribe(String queue, BiConsumer<Map<String, Object>, String> handler) {
        running.set(true);
        Thread thread = new Thread(() -> {
            String queueUrl = ensure(queue);
            while (running.get()) {
                try {
                    ReceiveMessageResponse response = sqs.receiveMessage(ReceiveMessageRequest.builder()
                            .queueUrl(queueUrl)
                            .maxNumberOfMessages(1)
                            .waitTimeSeconds(20)
                            .build());
                    for (Message message : response.messages()) {
                        handler.accept(fromJson(message.body()), message.receiptHandle());
                        sqs.deleteMessage(DeleteMessageRequest.builder()
                                .queueUrl(queueUrl)
                                .receiptHandle(message.receiptHandle())
                                .build());
                    }
                } catch (Exception e) {
                    try {
                        Thread.sleep(1000);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        return;
                    }
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

    private String ensure(String queue) {
        String name = queue.replace('.', '-');
        return queueUrls.computeIfAbsent(name, n -> {
            try {
                GetQueueUrlResponse response = sqs.getQueueUrl(GetQueueUrlRequest.builder().queueName(n).build());
                return response.queueUrl();
            } catch (QueueDoesNotExistException e) {
                CreateQueueResponse created = sqs.createQueue(CreateQueueRequest.builder().queueName(n).build());
                return created.queueUrl();
            }
        });
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