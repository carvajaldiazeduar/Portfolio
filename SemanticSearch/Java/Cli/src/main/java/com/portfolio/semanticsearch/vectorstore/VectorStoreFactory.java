package com.portfolio.semanticsearch.vectorstore;

public class VectorStoreFactory {
    public static VectorStoreAdapter create() {
        return new InMemoryVectorStore();
    }
}
