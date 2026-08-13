package com.portfolio.chatai;

import com.portfolio.chatai.model.ChatChoice;
import com.portfolio.chatai.model.ChatRequest;
import com.portfolio.chatai.model.ChatResponse;
import com.portfolio.chatai.model.ChatUsage;
import com.portfolio.chatai.provider.ChatProviderFactory;
import com.portfolio.chatai.provider.IChatProvider;
import com.portfolio.chatai.provider.ProviderNotConfiguredException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.lenient;
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
    private ChatProviderFactory factory;

    @MockBean
    private IChatProvider provider;

    private static final String VALID_BODY = "{\"messages\":[{\"role\":\"user\",\"content\":\"Hi\"}]}";

    @BeforeEach
    void setupProviders() {
        lenient().when(factory.resolve(isNull())).thenReturn("openai");
        lenient().when(factory.create("openai")).thenReturn(provider);
        lenient().when(factory.fallbackProvider()).thenReturn(null);
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
    void chatValidMessageReturnsAssistantResponse() throws Exception {
        ChatResponse mockResponse = new ChatResponse();
        mockResponse.setId("chatcmpl-test");
        mockResponse.setModel("gpt-4o-mini");
        mockResponse.setProvider("openai");
        ChatChoice choice = new ChatChoice();
        choice.setRole("assistant");
        choice.setContent("Hello!");
        mockResponse.setChoices(List.of(choice));
        ChatUsage usage = new ChatUsage();
        usage.setPrompt_tokens(5);
        usage.setCompletion_tokens(3);
        usage.setTotal_tokens(8);
        mockResponse.setUsage(usage);

        when(provider.completeChat(any())).thenReturn(mockResponse);

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(VALID_BODY))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("chatcmpl-test"))
                .andExpect(jsonPath("$.provider").value("openai"))
                .andExpect(jsonPath("$.choices[0].role").value("assistant"))
                .andExpect(jsonPath("$.choices[0].content").value("Hello!"))
                .andExpect(jsonPath("$.usage.total_tokens").value(8));
    }

    @Test
    void chatClientOverridesModelAndMaxTokens() throws Exception {
        ChatResponse mockResponse = new ChatResponse();
        mockResponse.setId("id");
        ChatChoice choice = new ChatChoice();
        choice.setRole("assistant");
        choice.setContent("");
        mockResponse.setChoices(List.of(choice));
        mockResponse.setUsage(new ChatUsage());
        when(provider.completeChat(any())).thenReturn(mockResponse);

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
        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"messages\":[]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Messages must not be empty"));
    }

    @Test
    void chatMissingMessagesReturnsBadRequest() throws Exception {
        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"model\":\"gpt-4o-mini\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Messages must not be empty"));
    }

    @Test
    void chatProviderFailureReturnsBadGateway() throws Exception {
        when(provider.completeChat(any())).thenThrow(new RuntimeException("upstream provider failed"));

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(VALID_BODY))
                .andExpect(status().is5xxServerError())
                .andExpect(jsonPath("$.error").exists());
    }

    // --- Nuevos tests de hot-switch / multi-provider / tolerancia ---

    @Test
    void requestProviderOverridesEnv() throws Exception {
        when(factory.resolve("azure")).thenReturn("azure");
        when(factory.create("azure")).thenReturn(provider);
        ChatResponse mockResponse = new ChatResponse();
        mockResponse.setId("chatcmpl-azure");
        ChatChoice choice = new ChatChoice();
        choice.setRole("assistant");
        choice.setContent("from azure");
        mockResponse.setChoices(List.of(choice));
        mockResponse.setUsage(new ChatUsage());
        when(provider.completeChat(any())).thenReturn(mockResponse);

        String body = "{\"messages\":[{\"role\":\"user\",\"content\":\"Hi\"}],\"provider\":\"azure\"}";

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.provider").value("azure"))
                .andExpect(jsonPath("$.choices[0].content").value("from azure"));
    }

    @Test
    void configuredProviderMissingKeyReturns400() throws Exception {
        when(factory.resolve("azure")).thenReturn("azure");
        when(factory.create("azure")).thenThrow(new ProviderNotConfiguredException("azure"));

        String body = "{\"messages\":[{\"role\":\"user\",\"content\":\"Hi\"}],\"provider\":\"azure\"}";

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Provider 'azure' is not configured (missing API key)"));
    }

    @Test
    void fallbackOnFailureReturns200() throws Exception {
        when(factory.fallbackProvider()).thenReturn("azure");
        when(factory.create("openai")).thenReturn(provider);
        when(factory.create("azure")).thenReturn(provider);
        ChatResponse fallbackResponse = new ChatResponse();
        fallbackResponse.setId("chatcmpl-fb");
        ChatChoice choice = new ChatChoice();
        choice.setRole("assistant");
        choice.setContent("fallback ok");
        fallbackResponse.setChoices(List.of(choice));
        fallbackResponse.setUsage(new ChatUsage());

        when(provider.completeChat(any()))
                .thenThrow(new RuntimeException("primary down"))
                .thenReturn(fallbackResponse);

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(VALID_BODY))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.provider").value("azure"))
                .andExpect(jsonPath("$.choices[0].content").value("fallback ok"));
    }

    @Test
    void fallbackMissingKeyReturns502() throws Exception {
        when(factory.fallbackProvider()).thenReturn("azure");
        when(factory.create("openai")).thenReturn(provider);
        when(factory.create("azure")).thenThrow(new ProviderNotConfiguredException("azure"));
        when(provider.completeChat(any())).thenThrow(new RuntimeException("primary timed out"));

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(VALID_BODY))
                .andExpect(status().is5xxServerError())
                .andExpect(jsonPath("$.error").exists());
    }

    @Test
    void providerTimeoutReturns502() throws Exception {
        when(factory.create("openai")).thenReturn(provider);
        when(provider.completeChat(any())).thenThrow(new RuntimeException("Read timed out: CHAT_TIMEOUT_MS exceeded"));

        mockMvc.perform(post("/api/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(VALID_BODY))
                .andExpect(status().is5xxServerError())
                .andExpect(jsonPath("$.error").value("Read timed out: CHAT_TIMEOUT_MS exceeded"));
    }

    private static ChatChoice emptyChoice() {
        ChatChoice c = new ChatChoice();
        c.setRole("assistant");
        c.setContent("");
        return c;
    }
}
