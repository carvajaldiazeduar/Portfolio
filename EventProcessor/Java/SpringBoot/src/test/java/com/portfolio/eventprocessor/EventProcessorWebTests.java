package com.portfolio.eventprocessor;

import com.portfolio.eventprocessor.queue.QueueAdapter;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "app.queue.driver=inmemory",
        "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration,org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration"
})
class EventProcessorWebTests {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private QueueAdapter queue;

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
    void healthReturnsOk() throws Exception {
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ok"))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void queuesReturnsRegisteredJobTypes() throws Exception {
        mockMvc.perform(get("/api/queues"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.queues").isArray())
                .andExpect(jsonPath("$.queues[*]").value(org.hamcrest.Matchers.hasItems(
                        org.hamcrest.Matchers.is("image.process"),
                        org.hamcrest.Matchers.is("email.bulk"),
                        org.hamcrest.Matchers.is("report.generate")
                )));
    }

    @Test
    void publishJobValidReturns202() throws Exception {
        mockMvc.perform(post("/api/jobs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"image.process\",\"data\":{\"imageUrl\":\"test.jpg\"}}"))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.message").value("Job queued"))
                .andExpect(jsonPath("$.type").value("image.process"))
                .andExpect(jsonPath("$.status").value("pending"));
        verify(queue).publish("image.process", Map.of("type", "image.process", "data", Map.of("imageUrl", "test.jpg")));
    }

    @Test
    void publishJobWithoutTypeReturns400() throws Exception {
        mockMvc.perform(post("/api/jobs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"data\":{\"imageUrl\":\"test.jpg\"}}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Type and data are required"));
    }

    @Test
    void publishJobUnknownTypeReturns400() throws Exception {
        mockMvc.perform(post("/api/jobs")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"unknown.type\",\"data\":{}}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Unknown job type: unknown.type"));
    }

    @Test
    void metricsReturnsPrometheusText() throws Exception {
        mockMvc.perform(post("/api/jobs")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"type\":\"image.process\",\"data\":{\"imageUrl\":\"test.jpg\"}}"));
        mockMvc.perform(get("/metrics"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith("text/plain"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("jobs_published_total")));
    }

    @Test
    void publishBatchQueuesMultipleJobs() throws Exception {
        mockMvc.perform(post("/api/jobs/batch")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"jobs\":[{\"type\":\"image.process\",\"data\":{\"imageUrl\":\"1.jpg\"}},{\"type\":\"email.bulk\",\"data\":{\"recipients\":[\"a@test.com\"],\"subject\":\"Test\"}}]}"))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.message").value("2 jobs queued"));
    }

    @Test
    void publishBatchEmptyReturns400() throws Exception {
        mockMvc.perform(post("/api/jobs/batch")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"jobs\":[]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Jobs array is required"));
    }
}
