package com.portfolio.conversor;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.closeTo;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class ConversorWebTests {

    @Autowired
    private MockMvc mockMvc;

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
    void categoriesListsAll() throws Exception {
        mockMvc.perform(get("/api/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length").exists())
                .andExpect(jsonPath("$.length").isArray())
                .andExpect(jsonPath("$.weight").isArray())
                .andExpect(jsonPath("$.temperature").isArray());
    }

    @Test
    void convertLength() throws Exception {
        mockMvc.perform(post("/api/convert")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"value\":1,\"from\":\"m\",\"to\":\"cm\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").value(closeTo(100, 0.001)))
                .andExpect(jsonPath("$.from").value("m"))
                .andExpect(jsonPath("$.to").value("cm"))
                .andExpect(jsonPath("$.value").value(1));
    }

    @Test
    void convertWeight() throws Exception {
        mockMvc.perform(post("/api/convert")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"value\":1,\"from\":\"kg\",\"to\":\"g\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").value(closeTo(1000, 0.001)));
    }

    @Test
    void convertTemperature() throws Exception {
        mockMvc.perform(post("/api/convert")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"value\":0,\"from\":\"C\",\"to\":\"F\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").value(closeTo(32, 0.001)));
    }

    @Test
    void convertTemperatureKtoC() throws Exception {
        mockMvc.perform(post("/api/convert")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"value\":273.15,\"from\":\"K\",\"to\":\"C\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").value(closeTo(0, 0.001)));
    }

    @Test
    void incompatibleUnitsReturns400() throws Exception {
        mockMvc.perform(post("/api/convert")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"value\":1,\"from\":\"m\",\"to\":\"kg\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Incompatible units: m -> kg"));
    }

    @Test
    void missingFieldsReturns400() throws Exception {
        mockMvc.perform(post("/api/convert")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"value\":1}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Missing fields: value, from, to"));
    }
}
