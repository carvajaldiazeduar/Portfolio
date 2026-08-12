package com.portfolio.semanticsearch;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "app.cache.type=local",
        "app.vector.dimension=1536"
})
class SemanticSearchWebTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private CacheAdapter cache;

    @BeforeEach
    void setUp() {
        cache.clear();
    }

    @Test
    void indexServesHtml() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk());
    }

    @Test
    void swaggerRedirects() throws Exception {
        mockMvc.perform(get("/swagger"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/swagger.html"));
    }

    @Test
    void openapiJsonServed() throws Exception {
        mockMvc.perform(get("/openapi.json"))
                .andExpect(status().isOk());
    }

    @Test
    void collectionsReturns200() throws Exception {
        mockMvc.perform(get("/api/collections"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.collections").isArray());
    }

    @Test
    void uploadWithFileReturns200() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "hello.txt", MediaType.TEXT_PLAIN_VALUE, "hello world".getBytes());
        mockMvc.perform(multipart("/api/upload").file(file))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Document indexed"))
                .andExpect(jsonPath("$.filename").value("hello.txt"));
    }

    @Test
    void uploadWithoutFileReturns400() throws Exception {
        mockMvc.perform(multipart("/api/upload"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("No file provided"));
    }

    @Test
    void searchWithoutQueryReturns400() throws Exception {
        mockMvc.perform(get("/api/search"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Query parameter 'q' is required"));
    }

    @Test
    void searchWithQueryReturnsResults() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "doc.txt", MediaType.TEXT_PLAIN_VALUE, "hello world".getBytes());
        mockMvc.perform(multipart("/api/upload").file(file)).andExpect(status().isOk());

        mockMvc.perform(get("/api/search").param("q", "hello"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.query").value("hello"))
                .andExpect(jsonPath("$.results").isArray());
    }

    @Test
    void searchCachesResult() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "doc.txt", MediaType.TEXT_PLAIN_VALUE, "hello world".getBytes());
        mockMvc.perform(multipart("/api/upload").file(file)).andExpect(status().isOk());

        mockMvc.perform(get("/api/search").param("q", "cached-query"))
                .andExpect(status().isOk());
        assert cache.get("search:cached-query") != null;
    }

    @Test
    void deleteCollectionReturns200() throws Exception {
        mockMvc.perform(delete("/api/collections/documents"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Collection 'documents' deleted"));
    }
}
