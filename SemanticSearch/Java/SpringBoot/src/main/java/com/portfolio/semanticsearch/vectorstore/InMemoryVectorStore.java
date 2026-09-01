package com.portfolio.semanticsearch.vectorstore;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class InMemoryVectorStore implements VectorStoreAdapter {
    private final Map<String, CollectionData> collections = new LinkedHashMap<>();

    private record CollectionData(List<String> docs, List<float[]> embeddings, List<Map<String, Object>> metadata) {
    }

    @Override
    public void connect() {
    }

    @Override
    public void addDocuments(List<String> documents, List<float[]> embeddings, List<Map<String, Object>> metadata) {
        String collection = System.getenv("VECTOR_COLLECTION") != null ? System.getenv("VECTOR_COLLECTION") : "documents";
        CollectionData data = collections.computeIfAbsent(collection, k -> new CollectionData(new ArrayList<>(), new ArrayList<>(), new ArrayList<>()));
        data.docs.addAll(documents);
        data.embeddings.addAll(embeddings);
        data.metadata.addAll(metadata);
    }

    @Override
    public List<SearchResult> search(float[] queryEmbedding, int nResults) {
        String collection = System.getenv("VECTOR_COLLECTION") != null ? System.getenv("VECTOR_COLLECTION") : "documents";
        CollectionData data = collections.get(collection);
        if (data == null || data.docs.isEmpty()) {
            return new ArrayList<>();
        }
        List<SearchResult> results = new ArrayList<>();
        int count = Math.min(nResults, data.docs.size());
        for (int i = 0; i < count; i++) {
            results.add(new SearchResult(data.docs.get(i), data.metadata.get(i), 0.0));
        }
        return results;
    }

    @Override
    public void deleteCollection(String collectionName) {
        collections.remove(collectionName);
    }

    @Override
    public List<String> listCollections() {
        return new ArrayList<>(collections.keySet());
    }

    @Override
    public void close() {
        collections.clear();
    }
}
