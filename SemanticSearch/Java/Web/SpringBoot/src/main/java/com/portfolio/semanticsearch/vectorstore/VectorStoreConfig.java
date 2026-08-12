package com.portfolio.semanticsearch.vectorstore;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class VectorStoreConfig {

    @Bean
    public VectorStoreAdapter vectorStoreAdapter(
            @Value("${app.vector.driver:chromadb}") String driver,
            @Value("${app.vector.chroma-url:http://localhost:8000}") String chromaUrl,
            @Value("${app.vector.dimension:1536}") int dimension,
            @Value("${app.vector.collection:documents}") String collection) {
        switch (driver) {
            case "pinecone":
                return new PineconeStore();
            case "pgvector":
                return new PgVectorStore();
            case "chromadb":
            default:
                ChromaDbVectorStore store = new ChromaDbVectorStore(chromaUrl, dimension, collection);
                try {
                    store.connect();
                } catch (Exception e) {
                    return new InMemoryVectorStore();
                }
                return store;
        }
    }
}
