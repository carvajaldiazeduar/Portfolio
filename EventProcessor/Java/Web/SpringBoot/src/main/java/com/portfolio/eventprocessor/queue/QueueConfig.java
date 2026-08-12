package com.portfolio.eventprocessor.queue;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class QueueConfig {

    @Bean
    public QueueAdapter queueAdapter(@Value("${app.queue.driver:redis}") String driver) {
        return switch (driver) {
            case "rabbitmq" -> new RabbitMqQueueAdapter();
            case "kafka" -> new KafkaQueueAdapter();
            case "sqs" -> new SqsQueueAdapter();
            case "inmemory" -> new InMemoryQueueAdapter();
            default -> new RedisQueueAdapter();
        };
    }
}
