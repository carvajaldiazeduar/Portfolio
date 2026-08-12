package com.portfolio.semanticsearch.vectorstore;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class PgVectorStore implements VectorStoreAdapter {
    private String url;
    private String user;
    private String pass;

    @Override
    public void connect() {
        try {
            String host = System.getenv().getOrDefault("DB_HOST", "db");
            String port = System.getenv().getOrDefault("DB_PORT", "5432");
            String db = System.getenv().getOrDefault("DB_NAME", "semantic_search");
            String u = System.getenv().getOrDefault("DB_USER", "postgres");
            String p = System.getenv().getOrDefault("DB_PASSWORD", "postgres");
            this.url = "jdbc:postgresql://" + host + ":" + port + "/" + db;
            this.user = u;
            this.pass = p;
            try (Connection conn = DriverManager.getConnection(url, user, pass);
                 Statement stmt = conn.createStatement()) {
                stmt.execute("CREATE EXTENSION IF NOT EXISTS vector");
            }
        } catch (Exception e) {
            throw new RuntimeException("Cannot connect to PostgreSQL/pgvector", e);
        }
    }

    private Connection open() throws SQLException {
        return DriverManager.getConnection(url, user, pass);
    }

    @Override
    public void addDocuments(List<String> documents, List<float[]> embeddings, List<Map<String, Object>> metadata) {
        String collection = System.getenv().getOrDefault("VECTOR_COLLECTION", "documents");
        String table = collection.replace('-', '_');
        ObjectMapper mapper = new ObjectMapper();
        try (Connection conn = open();
             Statement stmt = conn.createStatement()) {
            stmt.execute("CREATE TABLE IF NOT EXISTS " + table + " (id SERIAL PRIMARY KEY, document TEXT, embedding vector, metadata JSONB)");
            for (int i = 0; i < documents.size(); i++) {
                String emb = mapper.writeValueAsString(embeddings.get(i));
                String meta = mapper.writeValueAsString(metadata.get(i));
                try (PreparedStatement ps = conn.prepareStatement("INSERT INTO " + table + " (document, embedding, metadata) VALUES (?, ?::vector, ?::jsonb)")) {
                    ps.setString(1, documents.get(i));
                    ps.setString(2, emb);
                    ps.setString(3, meta);
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to add documents to pgvector", e);
        }
    }

    @Override
    public List<SearchResult> search(float[] queryEmbedding, int nResults) {
        String collection = System.getenv().getOrDefault("VECTOR_COLLECTION", "documents");
        String table = collection.replace('-', '_');
        ObjectMapper mapper = new ObjectMapper();
        List<SearchResult> results = new ArrayList<>();
        try (Connection conn = open();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT document, metadata, embedding <=> ?::vector AS distance FROM " + table + " ORDER BY embedding <=> ?::vector LIMIT ?")) {
            String emb = mapper.writeValueAsString(queryEmbedding);
            ps.setString(1, emb);
            ps.setString(2, emb);
            ps.setInt(3, nResults);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    SearchResult r = new SearchResult();
                    r.setDocument(rs.getString("document"));
                    String metaJson = rs.getString("metadata");
                    try {
                        r.setMetadata(mapper.readValue(metaJson, Map.class));
                    } catch (Exception ex) {
                        r.setMetadata(Map.of());
                    }
                    r.setDistance(rs.getDouble("distance"));
                    results.add(r);
                }
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to search pgvector", e);
        }
        return results;
    }

    @Override
    public void deleteCollection(String collectionName) {
        String table = collectionName.replace('-', '_');
        try (Connection conn = open();
             Statement stmt = conn.createStatement()) {
            stmt.execute("DROP TABLE IF EXISTS " + table);
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete collection", e);
        }
    }

    @Override
    public List<String> listCollections() {
        List<String> tables = new ArrayList<>();
        try (Connection conn = open();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(
                     "SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'vector_%'")) {
            while (rs.next()) {
                tables.add(rs.getString("table_name").replaceFirst("^vector_", ""));
            }
        } catch (Exception e) {
            return tables;
        }
        return tables;
    }

    @Override
    public void close() {
        this.url = null;
        this.user = null;
        this.pass = null;
    }
}
