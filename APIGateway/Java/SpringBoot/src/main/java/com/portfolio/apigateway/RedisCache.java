package com.portfolio.apigateway;

import org.springframework.data.redis.core.StringRedisTemplate;

import java.time.Duration;

public class RedisCache implements CacheAdapter {
    private final StringRedisTemplate redis;
    private final LocalCache fallback = new LocalCache();

    public RedisCache(StringRedisTemplate redis) {
        this.redis = redis;
    }

    @Override
    public String get(String key) {
        try {
            return redis.opsForValue().get(key);
        } catch (Exception e) {
            return fallback.get(key);
        }
    }

    @Override
    public void set(String key, String value, int ttlSeconds) {
        try {
            redis.opsForValue().set(key, value, Duration.ofSeconds(ttlSeconds));
        } catch (Exception e) {
            // ignore; redis unavailable
        }
    }

    @Override
    public void delete(String key) {
        try {
            redis.delete(key);
        } catch (Exception e) {
            // ignore
        }
    }

    @Override
    public long increment(String key, int ttlSeconds) {
        try {
            long next = redis.opsForValue().increment(key);
            redis.expire(key, java.time.Duration.ofSeconds(ttlSeconds));
            return next;
        } catch (Exception e) {
            return fallback.increment(key, ttlSeconds);
        }
    }

    @Override
    public void clear() {
        try {
            redis.getConnectionFactory().getConnection().flushDb();
        } catch (Exception e) {
            // ignore
        }
    }
}
