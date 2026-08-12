package com.portfolio.eventprocessor.metrics;

import org.springframework.stereotype.Component;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Component
public class MetricsService {

    private final ConcurrentHashMap<String, AtomicLong> counters = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, AtomicLong> histograms = new ConcurrentHashMap<>();
    private final String nl = System.lineSeparator();

    public void increment(String name, String... labels) {
        String key = name + String.join(",", labels);
        counters.computeIfAbsent(key, k -> new AtomicLong()).incrementAndGet();
    }

    public void observe(String name, double seconds, String... labels) {
        String key = name + String.join(",", labels);
        histograms.computeIfAbsent(key, k -> new AtomicLong()).addAndGet((long) (seconds * 1000));
    }

    public String render() {
        StringBuilder sb = new StringBuilder();
        String[] names = {"http_requests_total", "jobs_published_total", "jobs_processed_total"};
        for (String name : names) {
            for (var e : counters.entrySet()) {
                if (e.getKey().startsWith(name)) {
                    sb.append(e.getKey()).append(" ").append(e.getValue().get()).append(nl);
                }
            }
        }
        for (var e : histograms.entrySet()) {
            sb.append(e.getKey()).append(" ").append(e.getValue().get()).append(nl);
        }
        return sb.toString();
    }
}
