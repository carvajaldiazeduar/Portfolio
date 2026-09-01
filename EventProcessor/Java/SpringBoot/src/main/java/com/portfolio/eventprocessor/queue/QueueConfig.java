package com.portfolio.eventprocessor.queue;

import com.rabbitmq.client.ConnectionFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.core.StringRedisTemplate;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;

import java.net.URI;
import java.time.Duration;

@Configuration
public class QueueConfig {

    @Bean
    @ConditionalOnProperty(name = "app.queue.driver", havingValue = "redis", matchIfMissing = true)
    public StringRedisTemplate redisTemplate(@Value("${app.queue.redis.host:localhost}") String host,
                                             @Value("${app.queue.redis.port:6379}") int port) {
        org.springframework.data.redis.connection.RedisStandaloneConfiguration config =
                new org.springframework.data.redis.connection.RedisStandaloneConfiguration(host, port);
        org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory factory =
                new org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory(config);
        factory.afterPropertiesSet();
        return new StringRedisTemplate(factory);
    }

    @Bean
    @ConditionalOnProperty(name = "app.queue.driver", havingValue = "rabbitmq")
    public ConnectionFactory rabbitmqFactory(@Value("${RABBITMQ_URL:localhost:5672}") String url) {
        ConnectionFactory factory = new ConnectionFactory();
        try {
            factory.setUri(url);
        } catch (Exception e) {
            throw new IllegalStateException("Invalid RABBITMQ_URL", e);
        }
        return factory;
    }

    @Bean
    @ConditionalOnProperty(name = "app.queue.driver", havingValue = "sqs")
    public SqsClient sqsClient(@Value("${SQS_ENDPOINT:http://localhost:4566}") String endpoint,
                               @Value("${AWS_REGION:us-east-1}") String region) {
        return SqsClient.builder()
                .endpointOverride(URI.create(endpoint))
                .region(Region.of(region))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .httpClientBuilder(UrlConnectionHttpClient.builder()
                        .connectionTimeout(Duration.ofSeconds(5))
                        .socketTimeout(Duration.ofSeconds(35)))
                .build();
    }

    @Bean
    public QueueAdapter queueAdapter(@Value("${app.queue.driver:redis}") String driver,
                                     @Value("${KAFKA_BROKERS:localhost:9092}") String kafkaBrokers,
                                     ObjectProvider<StringRedisTemplate> redis,
                                     ObjectProvider<ConnectionFactory> rabbitmq,
                                     ObjectProvider<SqsClient> sqs) {
        return switch (driver) {
            case "rabbitmq" -> new RabbitMqQueueAdapter(rabbitmq.getIfAvailable());
            case "kafka" -> new KafkaQueueAdapter(kafkaBrokers);
            case "sqs" -> new SqsQueueAdapter(sqs.getIfAvailable());
            case "inmemory" -> new InMemoryQueueAdapter();
            default -> new RedisQueueAdapter(redis.getIfAvailable());
        };
    }
}