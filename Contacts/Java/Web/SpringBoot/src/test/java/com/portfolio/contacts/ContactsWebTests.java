package com.portfolio.contacts;

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
class ContactsWebTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ContactRepository repository;

    @BeforeEach
    void clean() {
        repository.deleteAll();
    }

    @Test
    void listEmpty() throws Exception {
        mockMvc.perform(get("/api/contacts"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void createAndList() throws Exception {
        mockMvc.perform(post("/api/contacts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Alice\",\"phone\":\"123-4567\",\"email\":\"alice@example.com\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").exists())
                .andExpect(jsonPath("$.name").value("Alice"));

        mockMvc.perform(get("/api/contacts"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].name").value("Alice"));
    }

    @Test
    void invalidEmailReturns400() throws Exception {
        mockMvc.perform(post("/api/contacts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Alice\",\"phone\":\"123-4567\",\"email\":\"not-an-email\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.email").value("Invalid email format"));
    }

    @Test
    void invalidPhoneReturns400() throws Exception {
        mockMvc.perform(post("/api/contacts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Alice\",\"phone\":\"abc\",\"email\":\"alice@example.com\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.phone").value("Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"));
    }

    @Test
    void missingNameReturns400() throws Exception {
        mockMvc.perform(post("/api/contacts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\",\"phone\":\"123-4567\",\"email\":\"alice@example.com\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.name").value("Name is required"));
    }

    @Test
    void searchReturnsMatches() throws Exception {
        createContact("Alice", "123-4567", "alice@example.com");
        createContact("Alexander", "789-0123", "alex@example.com");

        mockMvc.perform(get("/api/contacts/search").param("q", "al"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void deleteRemoves() throws Exception {
        var created = mockMvc.perform(post("/api/contacts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Alice\",\"phone\":\"123-4567\",\"email\":\"alice@example.com\"}"))
                .andExpect(status().isCreated())
                .andReturn();
        String body = created.getResponse().getContentAsString();
        long id = com.fasterxml.jackson.databind.JsonNode.class.cast(
                        new com.fasterxml.jackson.databind.ObjectMapper().readTree(body))
                .get("id").asLong();

        mockMvc.perform(delete("/api/contacts/" + id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Deleted"));

        mockMvc.perform(delete("/api/contacts/" + id))
                .andExpect(status().isNotFound());
    }

    private void createContact(String name, String phone, String email) throws Exception {
        mockMvc.perform(post("/api/contacts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"" + name + "\",\"phone\":\"" + phone + "\",\"email\":\"" + email + "\"}"))
                .andExpect(status().isCreated());
    }
}
