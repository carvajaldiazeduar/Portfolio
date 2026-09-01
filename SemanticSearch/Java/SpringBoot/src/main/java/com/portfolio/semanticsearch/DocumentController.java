package com.portfolio.semanticsearch;

import com.portfolio.semanticsearch.vectorstore.SearchResult;
import com.portfolio.semanticsearch.vectorstore.VectorStoreAdapter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("")
public class DocumentController {

    private final VectorStoreAdapter vectorStore;
    private final CacheAdapter cache;
    private final int dimension;

    public DocumentController(VectorStoreAdapter vectorStore,
                              CacheAdapter cache,
                              @Value("${app.vector.dimension:1536}") int dimension) {
        this.vectorStore = vectorStore;
        this.cache = cache;
        this.dimension = dimension;
    }

    @PostMapping(value = "/api/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> upload(@RequestParam(value = "file", required = false) MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "No file provided"));
        }
        String content;
        try {
            content = new String(file.getBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Could not read file"));
        }
        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("filename", file.getOriginalFilename());
        metadata.put("source", "upload");
        float[] embedding = new float[dimension];
        vectorStore.addDocuments(java.util.List.of(content), java.util.List.of(embedding), java.util.List.of(metadata));
        cache.delete("search:results");
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("message", "Document indexed");
        body.put("filename", file.getOriginalFilename());
        return ResponseEntity.ok(body);
    }

    @GetMapping("/api/search")
    public ResponseEntity<?> search(@RequestParam(required = false) String q) {
        if (q == null || q.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Query parameter 'q' is required"));
        }
        String cached = cache.get("search:" + q);
        if (cached != null) {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("query", q);
            body.put("results", parseResults(cached));
            return ResponseEntity.ok(body);
        }
        float[] embedding = new float[dimension];
        java.util.List<SearchResult> results = vectorStore.search(embedding, 5);
        cache.set("search:" + q, serializeResults(results), 300);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("query", q);
        body.put("results", results);
        return ResponseEntity.ok(body);
    }

    @GetMapping("/api/collections")
    public ResponseEntity<?> collections() {
        return ResponseEntity.ok(Map.of("collections", vectorStore.listCollections()));
    }

    @DeleteMapping("/api/collections/{name}")
    public ResponseEntity<?> deleteCollection(@PathVariable String name) {
        vectorStore.deleteCollection(name);
        cache.delete("search:results");
        return ResponseEntity.ok(Map.of("message", "Collection '" + name + "' deleted"));
    }

    private java.util.List<Map<String, Object>> parseResults(String cached) {
        try {
            return (java.util.List<Map<String, Object>>) new com.fasterxml.jackson.databind.ObjectMapper()
                    .readValue(cached, java.util.List.class);
        } catch (Exception e) {
            return java.util.List.of();
        }
    }

    private String serializeResults(java.util.List<SearchResult> results) {
        try {
            return new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(results);
        } catch (Exception e) {
            return "[]";
        }
    }
}
