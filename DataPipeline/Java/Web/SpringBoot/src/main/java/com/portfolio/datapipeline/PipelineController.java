package com.portfolio.datapipeline;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("")
public class PipelineController {

    private final DataWarehouseAdapter warehouse;
    private final CacheAdapter cache;

    public PipelineController(DataWarehouseAdapter warehouse, CacheAdapter cache) {
        this.warehouse = warehouse;
        this.cache = cache;
    }

    @GetMapping("/api/health")
    public Map<String, String> health() {
        warehouse.connect();
        Map<String, String> body = new LinkedHashMap<>();
        body.put("status", "healthy");
        body.put("warehouse", "connected");
        return body;
    }

    @GetMapping("/api/pipelines")
    public Map<String, Object> listPipelines() {
        String cached = cache.get("pipelines:all");
        if (cached != null) {
            return parse(cached);
        }
        List<String> tables = warehouse.listTables();
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("pipelines", tables);
        cache.set("pipelines:all", serialize(body), 300);
        return body;
    }

    @PostMapping("/api/pipelines/{name}/run")
    public ResponseEntity<?> runPipeline(@PathVariable String name, @RequestBody(required = false) Map<String, Object> data) {
        String source = data != null ? (String) data.getOrDefault("source", "") : "";
        String query = data != null ? (String) data.getOrDefault("query", "SELECT * FROM " + name) : "SELECT * FROM " + name;
        String target = data != null ? (String) data.getOrDefault("target", "processed_" + name) : "processed_" + name;
        Map<String, String> schema = data != null && data.containsKey("schema") ? (Map<String, String>) data.get("schema") : new java.util.LinkedHashMap<>();
        try {
            List<Map<String, Object>> results = warehouse.execute(query, null);
            warehouse.createTable(target, schema);
            warehouse.bulkInsert(target, results);
            cache.delete("pipelines:all");
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("message", "Pipeline executed");
            body.put("rows", results.size());
            body.put("target", target);
            return ResponseEntity.ok(body);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/api/sources")
    public Map<String, Object> listSources() {
        List<Map<String, Object>> sources = new java.util.ArrayList<>();
        sources.add(Map.of("name", "rest_api", "type", "REST", "status", "active"));
        sources.add(Map.of("name", "web_scraper", "type", "Scraper", "status", "active"));
        sources.add(Map.of("name", "scheduled_feed", "type", "Scheduled", "status", "active"));
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("sources", sources);
        return body;
    }

    private Map<String, Object> parse(String cached) {
        try {
            return (Map<String, Object>) new com.fasterxml.jackson.databind.ObjectMapper()
                    .readValue(cached, Map.class);
        } catch (Exception e) {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("pipelines", new java.util.ArrayList<>());
            return body;
        }
    }

    private String serialize(Map<String, Object> body) {
        try {
            return new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(body);
        } catch (Exception e) {
            return "{}";
        }
    }
}
