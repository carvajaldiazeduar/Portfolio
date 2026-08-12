package com.portfolio.passwordgenerator;

import java.util.concurrent.ConcurrentHashMap;

public class LocalCache implements CacheAdapter {
    private final ConcurrentHashMap<String, CacheEntry> store = new ConcurrentHashMap<>();

    @Override
    public String get(String key) {
        CacheEntry entry = store.get(key);
        if (entry != null && entry.expiresAt() > System.currentTimeMillis()) {
            return entry.value();
        }
        store.remove(key);
        return null;
    }

    @Override
    public void set(String key, String value, int ttlSeconds) {
        store.put(key, new CacheEntry(value, System.currentTimeMillis() + ttlSeconds * 1000L));
    }

    @Override
    public void delete(String key) {
        store.remove(key);
    }

    private record CacheEntry(String value, long expiresAt) {
    }
}
