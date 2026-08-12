package com.portfolio.tasks;

import org.springframework.data.redis.core.StringRedisTemplate;

import java.time.Duration;

public class RedisCache implements CacheAdapter {
    private final StringRedisTemplate redis;

    public RedisCache(StringRedisTemplate redis) {
        this.redis = redis;
    }

    @Override
    public String get(String key) {
        return redis.opsForValue().get(key);
    }

    @Override
    public void set(String key, String value, int ttlSeconds) {
        redis.opsForValue().set(key, value, Duration.ofSeconds(ttlSeconds));
    }

    @Override
    public void delete(String key) {
        redis.delete(key);
    }
}
