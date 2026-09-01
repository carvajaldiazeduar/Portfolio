package com.portfolio.semanticsearch.vectorstore;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ChromaDbVectorStore implements VectorStoreAdapter {
    private final RestTemplate restTemplate;
    private final ObjectMapper mapper;
    private final String chromaUrl;
    private final int dimension;
    private final String collection;
    private String collectionId;

    public ChromaDbVectorStore(String chromaUrl, int dimension, String collection) {
        this(new RestTemplate(), new ObjectMapper(), chromaUrl, dimension, collection);
    }

    public ChromaDbVectorStore(RestTemplate restTemplate, ObjectMapper mapper, String chromaUrl, int dimension, String collection) {
        this.restTemplate = restTemplate;
        this.mapper = mapper;
        this.chromaUrl = chromaUrl;
        this.dimension = dimension;
        this.collection = collection;
    }

    @Override
    public void connect() {
        try {
            ResponseEntity<String> res = restTemplate.getForEntity(chromaUrl + "/api/v2/collections", String.class);
            List<Map<String, Object>> existing = new ArrayList<>();
            try {
                existing = mapper.readValue(res.getBody(), mapper.getTypeFactory().constructCollectionType(List.class, Map.class));
            } catch (Exception ignored) {
            }
            String name = collection;
            String id = null;
            for (Map<String, Object> c : existing) {
                if (name.equals(c.get("name"))) {
                    id = (String) c.get("id");
                    break;
                }
            }
            if (id == null) {
                Map<String, Object> create = new LinkedHashMap<>();
                create.put("name", name);
                create.put("metadata", Map.of("hnsw:space", "cosine"));
                create.put("getOrCreate", true);
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_JSON);
                ResponseEntity<Map> created = restTemplate.postForEntity(chromaUrl + "/api/v2/collections", new HttpEntity<>(create, headers), Map.class);
                Map<String, Object> body = created.getBody();
                if (body != null) {
                    id = (String) body.get("id");
                    name = (String) body.getOrDefault("name", name);
                }
            }
            this.collectionId = id != null ? id : name;
        } catch (RestClientException e) {
            throw new RuntimeException("Cannot connect to ChromaDB", e);
        }
    }

    @Override
    public void addDocuments(List<String> documents, List<float[]> embeddings, List<Map<String, Object>> metadata) {
        List<String> ids = new ArrayList<>();
        List<String> docs = new ArrayList<>();
        List<List<Double>> embs = new ArrayList<>();
        List<Map<String, Object>> metas = new ArrayList<>();
        for (int i = 0; i < documents.size(); i++) {
            ids.add("doc_" + i);
            docs.add(documents.get(i));
            embs.add(toDoubles(embeddings.get(i)));
            metas.add(metadata.get(i));
        }
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("ids", ids);
        payload.put("documents", docs);
        payload.put("embeddings", embs);
        payload.put("metadatas", metas);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        try {
            restTemplate.postForEntity(chromaUrl + "/api/v2/collections/" + collectionId + "/add", new HttpEntity<>(payload, headers), String.class);
        } catch (RestClientException e) {
            throw new RuntimeException("Failed to add documents to ChromaDB", e);
        }
    }

    @Override
    @SuppressWarnings("unchecked")
    public List<SearchResult> search(float[] queryEmbedding, int nResults) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("query_embeddings", List.of(toDoubles(queryEmbedding)));
        payload.put("n_results", nResults);
        payload.put("include", List.of("documents", "metadatas", "distances"));
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        try {
            ResponseEntity<Map> res = restTemplate.postForEntity(chromaUrl + "/api/v2/collections/" + collectionId + "/query", new HttpEntity<>(payload, headers), Map.class);
            Map<String, Object> body = res.getBody();
            if (body == null) return new ArrayList<>();
            List<List<Object>> docs = (List<List<Object>>) body.getOrDefault("documents", List.of(List.of()));
            List<List<Object>> metas = (List<List<Object>>) body.getOrDefault("metadatas", List.of(List.of()));
            List<List<Object>> dists = (List<List<Object>>) body.getOrDefault("distances", List.of(List.of()));
            List<Object> d0 = docs.isEmpty() ? List.of() : docs.get(0);
            List<Object> m0 = metas.isEmpty() ? List.of() : metas.get(0);
            List<Object> dis0 = dists.isEmpty() ? List.of() : dists.get(0);
            List<SearchResult> results = new ArrayList<>();
            int size = Math.min(d0.size(), Math.min(m0.size(), dis0.size()));
            for (int i = 0; i < size; i++) {
                SearchResult r = new SearchResult();
                r.setDocument(d0.get(i) != null ? d0.get(i).toString() : "");
                r.setMetadata(m0.get(i) instanceof Map ? (Map<String, Object>) m0.get(i) : Map.of());
                r.setDistance(((Number) dis0.get(i)).doubleValue());
                results.add(r);
            }
            return results;
        } catch (RestClientException e) {
            throw new RuntimeException("Failed to query ChromaDB", e);
        }
    }

    @Override
    public void deleteCollection(String collectionName) {
        try {
            restTemplate.delete(chromaUrl + "/api/v2/collections/" + collectionName);
        } catch (RestClientException e) {
            // ignore
        }
    }

    @Override
    public List<String> listCollections() {
        try {
            ResponseEntity<List> res = restTemplate.getForEntity(chromaUrl + "/api/v2/collections", List.class);
            List<?> body = res.getBody();
            if (body == null) return new ArrayList<>();
            List<String> names = new ArrayList<>();
            for (Object item : body) {
                if (item instanceof Map) {
                    Object nameVal = ((Map<?, ?>) item).get("name");
                    names.add(nameVal == null ? "" : nameVal.toString());
                }
            }
            return names;
        } catch (RestClientException e) {
            return new ArrayList<>();
        }
    }

    @Override
    public void close() {
        this.collectionId = null;
    }

    private static List<Double> toDoubles(float[] arr) {
        List<Double> list = new ArrayList<>();
        for (float f : arr) {
            list.add((double) f);
        }
        return list;
    }
}
