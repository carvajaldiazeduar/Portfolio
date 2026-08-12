package com.portfolio.calculator;

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
class CalculatorWebTests {

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
    void addReturnsResult() throws Exception {
        mockMvc.perform(post("/api/calculate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"a\":2,\"b\":3,\"operator\":\"add\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").value(closeTo(5, 0.0001)));
    }

    @Test
    void subtractReturnsResult() throws Exception {
        mockMvc.perform(post("/api/calculate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"a\":5,\"b\":3,\"operator\":\"subtract\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").value(closeTo(2, 0.0001)));
    }

    @Test
    void multiplyReturnsResult() throws Exception {
        mockMvc.perform(post("/api/calculate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"a\":2,\"b\":3,\"operator\":\"multiply\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").value(closeTo(6, 0.0001)));
    }

    @Test
    void divideReturnsResult() throws Exception {
        mockMvc.perform(post("/api/calculate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"a\":6,\"b\":3,\"operator\":\"divide\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").value(closeTo(2, 0.0001)));
    }

    @Test
    void divideByZeroReturns400() throws Exception {
        mockMvc.perform(post("/api/calculate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"a\":5,\"b\":0,\"operator\":\"divide\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Cannot divide by zero"));
    }

    @Test
    void invalidOperatorReturns400() throws Exception {
        mockMvc.perform(post("/api/calculate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"a\":2,\"b\":3,\"operator\":\"power\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Invalid operator"));
    }

    @Test
    void invalidNumberInputReturns400() throws Exception {
        mockMvc.perform(post("/api/calculate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"a\":\"foo\",\"b\":3,\"operator\":\"add\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Invalid number input"));
    }
}
