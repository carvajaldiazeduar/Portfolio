package com.portfolio.apigateway;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;

@Configuration
public class CacheConfig {
    @Bean
    public CacheAdapter cacheAdapter(
            @Value("${app.cache.type:redis}") String cacheType,
            @Value("${app.cache.redis.host:localhost}") String redisHost,
            @Value("${app.cache.redis.port:6379}") int redisPort) {
        LocalCache localCache = new LocalCache();
        if ("local".equalsIgnoreCase(cacheType)) {
            return localCache;
        }
        try {
            RedisStandaloneConfiguration cfg = new RedisStandaloneConfiguration(redisHost, redisPort);
            LettuceConnectionFactory factory = new LettuceConnectionFactory(cfg);
            factory.afterPropertiesSet();
            StringRedisTemplate template = new StringRedisTemplate(factory);
            template.afterPropertiesSet();
            return new RedisCache(template);
        } catch (Exception e) {
            return localCache;
        }
    }
}
