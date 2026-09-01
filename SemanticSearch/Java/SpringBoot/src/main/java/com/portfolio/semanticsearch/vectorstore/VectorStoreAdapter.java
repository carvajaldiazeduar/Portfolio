package com.portfolio.semanticsearch.vectorstore;

import java.util.List;
import java.util.Map;

public interface VectorStoreAdapter {
    void connect();
    void addDocuments(List<String> documents, List<float[]> embeddings, List<Map<String, Object>> metadata);
    List<SearchResult> search(float[] queryEmbedding, int nResults);
    void deleteCollection(String collectionName);
    List<String> listCollections();
    void close();
}
