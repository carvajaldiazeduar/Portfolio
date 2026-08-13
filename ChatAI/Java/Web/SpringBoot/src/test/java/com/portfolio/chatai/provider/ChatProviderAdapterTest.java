package com.portfolio.chatai.provider;

import com.portfolio.chatai.model.ChatRequest;
import com.portfolio.chatai.model.ChatResponse;
import com.portfolio.chatai.model.ChatUsage;
import com.portfolio.chatai.model.Message;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class ChatProviderAdapterTest {

    private HttpServer server;
    private String baseUrl;
    private final ObjectMapper mapper = new ObjectMapper();
    private final AtomicReference<String> lastAuth = new AtomicReference<>();
    private final AtomicReference<String> lastPath = new AtomicReference<>();
    private final AtomicReference<String> lastBody = new AtomicReference<>();

    @BeforeEach
    void startServer() throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/v1/chat/completions", exchange -> {
            lastPath.set(exchange.getRequestURI().getPath());
            List<String> auth = exchange.getRequestHeaders().get("Authorization");
            lastAuth.set(auth == null || auth.isEmpty() ? null : auth.get(0));
            lastBody.set(new String(exchange.getRequestBody().readAllBytes()));
            String resp = "{\"id\":\"chatcmpl-x\",\"object\":\"chat.completion\",\"created\":1,\"model\":\"m\","
                    + "\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"Hi there!\"},\"finish_reason\":\"stop\"}],"
                    + "\"usage\":{\"prompt_tokens\":5,\"completion_tokens\":3,\"total_tokens\":8}}";
            byte[] bytes = resp.getBytes();
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, bytes.length);
            exchange.getResponseBody().write(bytes);
            exchange.close();
        });
        server.start();
        baseUrl = "http://127.0.0.1:" + server.getAddress().getPort() + "/v1";
    }

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    private static Message msg(String role, String content) {
        Message m = new Message();
        m.setRole(role);
        m.setContent(content);
        return m;
    }

    private static ChatRequest request(String provider) {
        ChatRequest req = new ChatRequest();
        req.setProvider(provider);
        req.setMessages(List.of(msg("user", "Hello")));
        return req;
    }

    @Test
    void openAiSendsBearerAuthAndParsesResponse() {
        OpenAiCompatibleChatProvider p =
                new OpenAiCompatibleChatProvider(mapper, baseUrl, "test-key", 3000);

        ChatResponse response = p.completeChat(request(null));

        assertEquals("chatcmpl-x", response.getId());
        assertEquals("openai", response.getProvider());
        assertEquals("assistant", response.getChoices().get(0).getRole());
        assertEquals("Hi there!", response.getChoices().get(0).getContent());
        ChatUsage usage = response.getUsage();
        assertNotNull(usage);
        assertEquals(5, usage.getPrompt_tokens());
        assertEquals(3, usage.getCompletion_tokens());
        assertEquals(8, usage.getTotal_tokens());
        assertEquals("Bearer test-key", lastAuth.get());
        assertEquals("/v1/chat/completions", lastPath.get());
        assertNotNull(lastBody.get());
    }

    @Test
    void timeoutIsRespectedAndThrowsFast() throws IOException {
        server.removeContext("/v1/chat/completions");
        HttpHandler slow = exchange -> {
            try {
                Thread.sleep(2000); // simulate an upstream that hangs
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                exchange.close();
            }
        };
        server.createContext("/v1/chat/completions", slow);

        OpenAiCompatibleChatProvider p =
                new OpenAiCompatibleChatProvider(mapper, baseUrl, "test-key", 300);

        RuntimeException ex = assertThrows(RuntimeException.class, () -> p.completeChat(request(null)));
        assertEquals(true, ex.getMessage().contains("Provider error"), ex.getMessage());
    }
}
