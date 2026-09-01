package com.portfolio.semanticsearch;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

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
        store.put(key, new Entry(value, System.currentTimeMillis() + ttlSeconds * 1000L));
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
