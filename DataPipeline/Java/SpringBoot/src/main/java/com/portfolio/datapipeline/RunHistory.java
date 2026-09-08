package com.portfolio.datapipeline;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

public class RunHistory {

    private static final int MAX_RUNS = 50;

    private final List<Map<String, Object>> runs = new CopyOnWriteArrayList<>();

    public void record(String pipeline, int rows, long durationMs) {
        Map<String, Object> entry = new LinkedHashMap<>();
        entry.put("pipeline", pipeline);
        entry.put("rows", rows);
        entry.put("duration_ms", durationMs);
        entry.put("timestamp", System.currentTimeMillis());
        runs.add(entry);
        while (runs.size() > MAX_RUNS) {
            runs.remove(0);
        }
    }

    public List<Map<String, Object>> recent() {
        return List.copyOf(runs);
    }
}