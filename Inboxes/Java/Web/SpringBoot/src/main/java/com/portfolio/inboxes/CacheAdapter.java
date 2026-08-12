package com.portfolio.inboxes;

public interface CacheAdapter {
    String get(String key);

    void set(String key, String value, int ttlSeconds);

    default void set(String key, String value) {
        set(key, value, 300);
    }

    void delete(String key);
}
