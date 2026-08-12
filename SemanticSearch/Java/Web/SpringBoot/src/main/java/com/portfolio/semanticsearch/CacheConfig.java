package com.portfolio.semanticsearch;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.util.ArrayList;
import java.util.List;

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
            return new CacheComposite(List.of(localCache, new RedisCache(template)));
        } catch (Exception e) {
            return localCache;
        }
    }

    private static final class CacheComposite implements CacheAdapter {
        private final List<CacheAdapter> layers;

        CacheComposite(List<CacheAdapter> layers) {
            this.layers = layers;
        }

        @Override
        public String get(String key) {
            return layers.get(0).get(key);
        }

        @Override
        public void set(String key, String value, int ttlSeconds) {
            for (CacheAdapter layer : layers) {
                layer.set(key, value, ttlSeconds);
            }
        }

        @Override
        public void delete(String key) {
            for (CacheAdapter layer : layers) {
                layer.delete(key);
            }
        }

        @Override
        public void clear() {
            for (CacheAdapter layer : layers) {
                layer.clear();
            }
        }
    }
}
