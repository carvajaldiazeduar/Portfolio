package com.portfolio.chronometer;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class ChronometerWebTests {

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
    void stateReflectsStopwatch() throws Exception {
        reset();
        mockMvc.perform(get("/api/state"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.running").value(false))
                .andExpect(jsonPath("$.time").value(0.0))
                .andExpect(jsonPath("$.laps").isArray());
    }

    @Test
    void startSetsRunning() throws Exception {
        reset();
        mockMvc.perform(post("/api/start"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.running").value(true));
    }

    @Test
    void stopPausesAndKeepsElapsed() throws Exception {
        reset();
        mockMvc.perform(post("/api/start"));
        mockMvc.perform(post("/api/stop"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.running").value(false));
    }

    @Test
    void resetClearsState() throws Exception {
        reset();
        mockMvc.perform(post("/api/start"));
        mockMvc.perform(post("/api/reset"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.running").value(false))
                .andExpect(jsonPath("$.time").value(0.0))
                .andExpect(jsonPath("$.laps", hasSize(0)));
    }

    @Test
    void lapRecordsLapWhenRunning() throws Exception {
        reset();
        mockMvc.perform(post("/api/start"));
        mockMvc.perform(post("/api/lap"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.laps", hasSize(1)))
                .andExpect(jsonPath("$.laps[0].cumulative").isNumber())
                .andExpect(jsonPath("$.laps[0].split").isNumber())
                .andExpect(jsonPath("$.laps[0].cumulative_str").isString())
                .andExpect(jsonPath("$.laps[0].split_str").isString());
    }

    private void reset() throws Exception {
        mockMvc.perform(post("/api/reset"))
                .andExpect(status().isOk());
    }
}
