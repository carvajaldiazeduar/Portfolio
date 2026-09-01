package com.portfolio.apigateway;

import com.portfolio.apigateway.auth.JwtUtil;
import com.portfolio.apigateway.ratelimit.RateLimitFilter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.client.RestTemplate;

import java.util.LinkedHashMap;
import java.util.Map;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "app.cache.type=local",
        "app.routes.users.limit=50",
        "JWT_SECRET=test-secret"
})
class APIGatewayWebTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private CacheAdapter cache;

    @MockBean
    private RestTemplate restTemplate;

    private String adminToken;

    @BeforeEach
    void setUp() {
        cache.clear();
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("id", 1);
        payload.put("username", "admin");
        payload.put("roles", java.util.List.of("admin"));
        payload.put("exp", (System.currentTimeMillis() / 1000) + 3600);
        adminToken = JwtUtil.sign(payload, "test-secret");
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
    void healthReturnsOk() throws Exception {
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ok"));
    }

    @Test
    void loginWithValidCredentialsReturnsToken() throws Exception {
        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"admin\",\"password\":\"admin\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists());
    }

    @Test
    void loginWithInvalidCredentialsReturns401() throws Exception {
        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"wrong\",\"password\":\"wrong\"}"))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void loginWithMissingCredentialsReturns400() throws Exception {
        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void protectedRouteWithoutTokenReturns401() throws Exception {
        mockMvc.perform(get("/api/users"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Missing or invalid Authorization header"));
    }

    @Test
    void protectedRouteWithInvalidTokenReturns401() throws Exception {
        mockMvc.perform(get("/api/users")
                        .header("Authorization", "Bearer not-a-valid-token"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Invalid or expired token"));
    }

    @Test
    void protectedRouteWithValidTokenPassesAuth() throws Exception {
        when(restTemplate.getForEntity(anyString(), any(Class.class)))
                .thenReturn(ResponseEntity.ok("upstream-ok"));
        mockMvc.perform(get("/api/users")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());
    }

    @Test
    void rateLimitingReturns429WhenExceeded() throws Exception {
        when(restTemplate.getForEntity(anyString(), any(Class.class)))
                .thenReturn(ResponseEntity.ok("upstream-ok"));

        int allowed = 0;
        int lastStatus = 0;
        for (int i = 0; i < 55; i++) {
            int status = mockMvc.perform(get("/api/users")
                            .header("Authorization", "Bearer " + adminToken))
                    .andReturn().getResponse().getStatus();
            if (status == 200) allowed++;
            lastStatus = status;
        }
        assert allowed == 50;
        assert lastStatus == 429;
    }
}
