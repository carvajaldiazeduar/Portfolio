package com.portfolio.passwordgenerator;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
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
class PasswordGeneratorWebTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private StoredPasswordRepository repository;

    private final ObjectMapper mapper = new ObjectMapper();

    @BeforeEach
    void clean() {
        repository.deleteAll();
    }

    @Test
    void listEmpty() throws Exception {
        mockMvc.perform(get("/api/passwords"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void indexReturnsHtml() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk());
    }

    @Test
    void generateDefaultReturns16Chars() throws Exception {
        String password = generate("");
        assertEquals(16, password.length());
    }

    @Test
    void generateCustomLength() throws Exception {
        assertEquals(24, generate("?length=24").length());
    }

    @Test
    void generateNoUppercase() throws Exception {
        assertFalse(generate("?uppercase=false").matches(".*[A-Z].*"));
    }

    @Test
    void generateNoSymbols() throws Exception {
        assertFalse(generate("?symbols=false").matches(".*[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?].*"));
    }

    @Test
    void generateAtLeastOneFromEachEnabled() throws Exception {
        String password = generate("?length=20&symbols=true");
        assertTrue(password.matches(".*[A-Z].*"));
        assertTrue(password.matches(".*[a-z].*"));
        assertTrue(password.matches(".*[0-9].*"));
        assertTrue(password.matches(".*[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?].*"));
    }

    @Test
    void generateAllDisabledReturns400() throws Exception {
        mockMvc.perform(get("/api/generate")
                        .param("uppercase", "false")
                        .param("lowercase", "false")
                        .param("numbers", "false")
                        .param("symbols", "false"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.flags").value("At least one character category must be enabled"));
    }

    @Test
    void generateZeroLengthReturns400() throws Exception {
        mockMvc.perform(get("/api/generate").param("length", "0"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.length").value("Password length must be at least 1"));
    }

    @Test
    void generateLengthTooShortForCategoriesReturns400() throws Exception {
        mockMvc.perform(get("/api/generate").param("length", "2"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.length").value("Password length must be at least 3 when 3 categories are enabled"));
    }

    @Test
    void createAndList() throws Exception {
        mockMvc.perform(post("/api/passwords")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"password\":\"abc123\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").exists())
                .andExpect(jsonPath("$.password").value("abc123"));

        mockMvc.perform(get("/api/passwords"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].password").value("abc123"));
    }

    @Test
    void blankPasswordReturns400() throws Exception {
        mockMvc.perform(post("/api/passwords")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"password\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.password").value("Password is required"));
    }

    @Test
    void deleteRemoves() throws Exception {
        long id = createStored("secret");
        mockMvc.perform(delete("/api/passwords/" + id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Deleted"));
        mockMvc.perform(delete("/api/passwords/" + id))
                .andExpect(status().isNotFound());
    }

    private String generate(String query) throws Exception {
        MvcResult result = mockMvc.perform(get("/api/generate" + query))
                .andExpect(status().isOk())
                .andReturn();
        return mapper.readTree(result.getResponse().getContentAsString()).get("password").asText();
    }

    private long createStored(String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/passwords")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"password\":\"" + password + "\"}"))
                .andExpect(status().isCreated())
                .andReturn();
        JsonNode node = mapper.readTree(result.getResponse().getContentAsString());
        return node.get("id").asLong();
    }
}
