package com.portfolio.datapipeline;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

public class LocalCache implements CacheAdapter {
    private final ConcurrentHashMap<String, Entry> store = new ConcurrentHashMap<>();

    @Override
    public String get(String key) {
        Entry entry = store.get(key);
        if (entry != null && entry.expiresAt() > System.currentTimeMillis()) {
            return entry.value();
        }
        store.remove(key);
        return null;
    }

    @Override
    public void set(String key, String value, int ttlSeconds) {
        long expiresAt = ttlSeconds > 0 ? System.currentTimeMillis() + ttlSeconds * 1000L : Long.MAX_VALUE;
        store.put(key, new Entry(value, expiresAt));
    }

    @Override
    public void delete(String key) {
        store.remove(key);
    }

    @Override
    public void clear() {
        store.clear();
    }

    private record Entry(String value, long expiresAt) {
    }
}
