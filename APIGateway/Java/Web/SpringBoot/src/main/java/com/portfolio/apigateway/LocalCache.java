package com.portfolio.apigateway;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

public class LocalCache implements CacheAdapter {
    private final ConcurrentHashMap<String, Entry> store = new ConcurrentHashMap<>();

    @Override
    public String get(String key) {
        Entry entry = store.get(key);
        if (entry == null || entry.expires() <= System.currentTimeMillis()) {
            store.remove(key);
            return null;
        }
        return entry.value();
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
    public long increment(String key, int ttlSeconds) {
        Entry entry = store.get(key);
        if (entry == null || entry.expires() <= System.currentTimeMillis()) {
            store.put(key, new Entry("1", ttlSeconds > 0 ? System.currentTimeMillis() + ttlSeconds * 1000L : Long.MAX_VALUE));
            return 1;
        }
        AtomicLong counter = entry.counter();
        long next = counter.incrementAndGet();
        return next;
    }

    @Override
    public void clear() {
        store.clear();
    }

    private record Entry(String value, long expires, AtomicLong counter) {
        Entry(String value, long expires) {
            this(value, expires, new AtomicLong(parseLong(value)));
        }
        private static long parseLong(String v) {
            return v == null ? 0L : Long.parseLong(v);
        }
    }
}
