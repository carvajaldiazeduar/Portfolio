package com.portfolio.datapipeline;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "app.cache.type=local",
        "app.warehouse.driver=duckdb",
        "app.warehouse.path="
})
class DataPipelineWebTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private CacheAdapter cache;

    @Autowired
    private DataWarehouseAdapter warehouse;

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
    void healthReturns200() throws Exception {
        mockMvc.perform(get("/api/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("healthy"))
                .andExpect(jsonPath("$.warehouse").value("connected"));
    }

    @Test
    void pipelinesReturnsArray() throws Exception {
        mockMvc.perform(get("/api/pipelines"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.pipelines").isArray());
    }

    @Test
    void sourcesReturns200() throws Exception {
        mockMvc.perform(get("/api/sources"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sources").isArray())
                .andExpect(jsonPath("$.sources.length()").value(3));
    }

    @Test
    void runPipelineMissingTableReturns500() throws Exception {
        mockMvc.perform(post("/api/pipelines/this_table_does_not_exist/run")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().is5xxServerError())
                .andExpect(jsonPath("$.error").exists());
    }

    @Test
    void runPipelineExecutesSuccessfully() throws Exception {
        warehouse.connect();
        warehouse.execute("CREATE TABLE etl_users (id INTEGER, name VARCHAR)", null);
        List<Map<String, Object>> rows = new java.util.ArrayList<>();
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", 1);
        row.put("name", "Alice");
        rows.add(row);
        warehouse.bulkInsert("etl_users", rows);

        mockMvc.perform(post("/api/pipelines/etl_users/run")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"schema\":{\"id\":\"INTEGER\",\"name\":\"VARCHAR\"}}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Pipeline executed"))
                .andExpect(jsonPath("$.rows").value(1))
                .andExpect(jsonPath("$.target").value("processed_etl_users"));
    }
}
