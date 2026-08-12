package com.portfolio.semanticsearch.vectorstore;

public class PineconeStore implements VectorStoreAdapter {
    @Override
    public void connect() {
    }

    @Override
    public void addDocuments(java.util.List<String> documents, java.util.List<float[]> embeddings, java.util.List<java.util.Map<String, Object>> metadata) {
    }

    @Override
    public java.util.List<SearchResult> search(float[] queryEmbedding, int nResults) {
        return new java.util.ArrayList<>();
    }

    @Override
    public void deleteCollection(String collectionName) {
    }

    @Override
    public java.util.List<String> listCollections() {
        return new java.util.ArrayList<>();
    }

    @Override
    public void close() {
    }
}
