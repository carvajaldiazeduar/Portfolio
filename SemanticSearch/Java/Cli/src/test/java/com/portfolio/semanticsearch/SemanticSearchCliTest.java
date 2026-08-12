package com.portfolio.semanticsearch;

import com.portfolio.semanticsearch.vectorstore.SearchResult;
import com.portfolio.semanticsearch.vectorstore.VectorStoreAdapter;
import com.portfolio.semanticsearch.vectorstore.VectorStoreFactory;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SemanticSearchCliTest {

    @Test
    void factoryCreatesVectorStore() {
        VectorStoreAdapter store = VectorStoreFactory.create();
        assertNotNull(store);
    }

    @Test
    void inMemoryStoreAddAndSearch() {
        VectorStoreAdapter store = new com.portfolio.semanticsearch.vectorstore.InMemoryVectorStore();
        store.connect();

        store.addDocuments(
                List.of("hello world", "second doc"),
                List.of(new float[4], new float[4]),
                List.of(Map.of("filename", "a.txt"), Map.of("filename", "b.txt"))
        );

        List<SearchResult> results = store.search(new float[4], 5);
        assertEquals(2, results.size());
        assertEquals("hello world", results.get(0).getDocument());
        assertEquals("second doc", results.get(1).getDocument());
    }

    @Test
    void inMemoryStoreListAndDeleteCollection() {
        VectorStoreAdapter store = new com.portfolio.semanticsearch.vectorstore.InMemoryVectorStore();
        store.connect();

        assertTrue(store.listCollections().isEmpty());
        store.addDocuments(List.of("x"), List.of(new float[4]), List.of(Map.of()));
        assertTrue(store.listCollections().contains("documents"));
        store.deleteCollection("documents");
        assertTrue(store.listCollections().isEmpty());
    }

    @Test
    void inMemoryStoreSearchEmptyReturnsEmpty() {
        VectorStoreAdapter store = new com.portfolio.semanticsearch.vectorstore.InMemoryVectorStore();
        store.connect();
        assertTrue(store.search(new float[4], 5).isEmpty());
    }
}
