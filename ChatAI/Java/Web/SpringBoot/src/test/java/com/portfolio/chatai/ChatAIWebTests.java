package com.portfolio.chatai;

import com.portfolio.chatai.model.ChatChoice;
import com.portfolio.chatai.model.ChatRequest;
import com.portfolio.chatai.model.ChatResponse;
import com.portfolio.chatai.model.ChatUsage;
import com.portfolio.chatai.provider.IChatProvider;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class ChatAIWebTests {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private IChatProvider provider;

    private static final String VALID_BODY = "{\"messages\":[{\"role\":\"user\",\"content\":\"Hi\"}]}";

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
    void chatValidMessageReturnsAssistantResponse() throws Exception {
        ChatResponse mockResponse = new ChatResponse();
        mockResponse.setId("chatcmpl-test");
        mockResponse.setModel("gpt-4o-mini");
        ChatChoice choice = new ChatChoice();
        choice.setRole("assistant");
        choice.setContent("Hello!");
        mockResponse.setChoices(List.of(choice));
        ChatUsage usage = new ChatUsage();
        usage.setPrompt_tokens(5);
        usage.setCompletion_tokens(3);
        usage.setTotal_tokens(8);
        mockResponse.setUsage(usage);

        when(provider.completeChat(any(ChatRequest.class))).thenReturn(mockResponse);

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(VALID_BODY))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("chatcmpl-test"))
                .andExpect(jsonPath("$.choices[0].role").value("assistant"))
                .andExpect(jsonPath("$.choices[0].content").value("Hello!"))
                .andExpect(jsonPath("$.usage.total_tokens").value(8));
    }

    @Test
    void chatClientOverridesModelAndMaxTokens() throws Exception {
        ChatResponse mockResponse = new ChatResponse();
        mockResponse.setId("id");
        mockResponse.setChoices(List.of(emptyChoice()));
        mockResponse.setUsage(new ChatUsage());
        when(provider.completeChat(any(ChatRequest.class))).thenReturn(mockResponse);

        String body = "{\"messages\":[{\"role\":\"user\",\"content\":\"Hi\"}],\"model\":\"gpt-4-turbo\",\"temperature\":0.2,\"max_tokens\":500}";

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());

        ArgumentCaptor<ChatRequest> captor = ArgumentCaptor.forClass(ChatRequest.class);
        verify(provider, times(1)).completeChat(captor.capture());
        ChatRequest captured = captor.getValue();
        assertEquals("gpt-4-turbo", captured.getModel());
        assertEquals(0.2, captured.getTemperature());
        assertEquals(500, captured.getMax_tokens());
    }

    @Test
    void chatEmptyMessagesReturnsBadRequest() throws Exception {
        String body = "{\"messages\":[]}";

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Messages must not be empty"));
    }

    @Test
    void chatMissingMessagesReturnsBadRequest() throws Exception {
        String body = "{\"model\":\"gpt-4o-mini\"}";

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Messages must not be empty"));
    }

    @Test
    void chatProviderFailureReturnsBadGateway() throws Exception {
        when(provider.completeChat(any(ChatRequest.class)))
                .thenThrow(new RuntimeException("upstream provider failed"));

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(VALID_BODY))
                .andExpect(status().is5xxServerError())
                .andExpect(jsonPath("$.error").exists());
    }

    private static ChatChoice emptyChoice() {
        ChatChoice c = new ChatChoice();
        c.setRole("assistant");
        c.setContent("");
        return c;
    }
}
