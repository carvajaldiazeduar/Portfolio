package com.portfolio.apigateway;

public interface CacheAdapter {
    String get(String key);
    void set(String key, String value, int ttlSeconds);
    void delete(String key);
    long increment(String key, int ttlSeconds);
    void clear();
}
