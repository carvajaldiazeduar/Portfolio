package com.portfolio.inboxes;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "app.db.driver=sqlite",
        "app.db.file=test.db",
        "app.cache.type=local"
})
class InboxesWebTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private MessageRepository repository;

    @Autowired
    private CacheAdapter cache;

    @BeforeEach
    void clean() {
        repository.deleteAll();
        cache.delete("messages:all");
    }

    @Test
    void listEmpty() throws Exception {
        mockMvc.perform(get("/api/messages"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void createAndList() throws Exception {
        mockMvc.perform(post("/api/messages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"from\":\"Alice\",\"subject\":\"Hello\",\"body\":\"World\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").exists())
                .andExpect(jsonPath("$.subject").value("Hello"))
                .andExpect(jsonPath("$.from").value("Alice"))
                .andExpect(jsonPath("$.read").value(false));

        mockMvc.perform(get("/api/messages"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].subject").value("Hello"));
    }

    @Test
    void getByIdMarksRead() throws Exception {
        var created = mockMvc.perform(post("/api/messages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"from\":\"Alice\",\"subject\":\"Hello\",\"body\":\"World\"}"))
                .andExpect(status().isCreated())
                .andReturn();
        String body = created.getResponse().getContentAsString();
        long id = new com.fasterxml.jackson.databind.ObjectMapper().readTree(body).get("id").asLong();

        mockMvc.perform(get("/api/messages/" + id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.read").value(true));

        mockMvc.perform(get("/api/messages"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].read").value(true));
    }

    @Test
    void getByIdNotFound() throws Exception {
        mockMvc.perform(get("/api/messages/999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteRemoves() throws Exception {
        var created = mockMvc.perform(post("/api/messages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"from\":\"Alice\",\"subject\":\"Hello\",\"body\":\"World\"}"))
                .andExpect(status().isCreated())
                .andReturn();
        String body = created.getResponse().getContentAsString();
        long id = new com.fasterxml.jackson.databind.ObjectMapper().readTree(body).get("id").asLong();

        mockMvc.perform(delete("/api/messages/" + id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Deleted"));

        mockMvc.perform(get("/api/messages"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void deleteNotFound() throws Exception {
        mockMvc.perform(delete("/api/messages/999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void missingFromReturns400() throws Exception {
        mockMvc.perform(post("/api/messages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"from\":\"\",\"subject\":\"Hello\",\"body\":\"World\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.from").value("From is required"));
    }

    @Test
    void missingSubjectReturns400() throws Exception {
        mockMvc.perform(post("/api/messages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"from\":\"Alice\",\"subject\":\"\",\"body\":\"World\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.subject").value("Subject is required"));
    }

    @Test
    void missingBodyReturns400() throws Exception {
        mockMvc.perform(post("/api/messages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"from\":\"Alice\",\"subject\":\"Hello\",\"body\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.body").value("Body is required"));
    }
}
