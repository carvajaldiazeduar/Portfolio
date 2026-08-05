using System.Net;
using System.Net.Http.Json;
using System.Text;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace ChatAI.Tests;

public class FakeChatProvider : IChatProvider
{
    public ChatResponse? Response { get; set; }
    public bool ThrowOnCall { get; set; }
    public ChatRequest? LastRequest { get; set; }

    public Task<ChatResponse> CompleteAsync(ChatRequest request)
    {
        LastRequest = request;
        if (ThrowOnCall)
            throw new InvalidOperationException("upstream provider failed");
        return Task.FromResult(Response ?? new ChatResponse
        {
            Id = "chatcmpl-test",
            Model = "gpt-4o-mini",
            Choices = new List<ChatChoice> { new ChatChoice { Role = "assistant", Content = "Hello!" } },
            Usage = new ChatUsage { PromptTokens = 5, CompletionTokens = 3, TotalTokens = 8 },
        });
    }
}

public class MockHttpMessageHandler : HttpMessageHandler
{
    public string? RequestBody { get; private set; }
    public string? RequestUri { get; private set; }
    public HttpStatusCode StatusCode { get; set; } = HttpStatusCode.OK;
    public string ResponseBody { get; set; } = "";

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        RequestUri = request.RequestUri?.ToString();
        RequestBody = request.Content != null ? await request.Content.ReadAsStringAsync(cancellationToken) : null;
        return new HttpResponseMessage(StatusCode)
        {
            Content = new StringContent(ResponseBody, Encoding.UTF8, "application/json"),
        };
    }
}

public class ChatAITests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ChatAITests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Index_ReturnsSuccess()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/");
        response.EnsureSuccessStatusCode();
    }

    [Fact]
    public async Task Health_ReturnsOk()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/health");
        response.EnsureSuccessStatusCode();
        var data = await response.Content.ReadFromJsonAsync<Dictionary<string, string>>();
        Assert.Equal("ok", data!["status"]);
    }

    [Fact]
    public async Task Chat_ValidMessage_ReturnsAssistantResponse()
    {
        var provider = new FakeChatProvider();
        var client = _factory.WithWebHostBuilder(b =>
        {
            b.ConfigureTestServices(s => s.AddSingleton<IChatProvider>(provider));
        }).CreateClient();

        var response = await client.PostAsJsonAsync("/api/chat", new
        {
            messages = new[] { new { role = "user", content = "Hi" } },
        });

        response.EnsureSuccessStatusCode();
        var data = await response.Content.ReadFromJsonAsync<ChatResponse>();
        Assert.Equal("assistant", data!.Choices[0].Role);
        Assert.Equal("Hello!", data.Choices[0].Content);
        Assert.Equal("chatcmpl-test", data.Id);
    }

    [Fact]
    public async Task Chat_ClientOverridesModelAndMaxTokens()
    {
        var provider = new FakeChatProvider();
        var client = _factory.WithWebHostBuilder(b =>
        {
            b.ConfigureTestServices(s => s.AddSingleton<IChatProvider>(provider));
        }).CreateClient();

        var response = await client.PostAsJsonAsync("/api/chat", new
        {
            messages = new[] { new { role = "user", content = "Hi" } },
            model = "gpt-4-turbo",
            temperature = 0.2,
            max_tokens = 500,
        });

        response.EnsureSuccessStatusCode();
        Assert.Equal("gpt-4-turbo", provider.LastRequest!.Model);
        Assert.Equal(0.2, provider.LastRequest.Temperature);
        Assert.Equal(500, provider.LastRequest.MaxTokens);
    }

    [Fact]
    public async Task Chat_EmptyMessages_ReturnsBadRequest()
    {
        var client = _factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/chat", new { messages = new object[0] });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Chat_ProviderFailure_ReturnsBadGateway()
    {
        var provider = new FakeChatProvider { ThrowOnCall = true };
        var client = _factory.WithWebHostBuilder(b =>
        {
            b.ConfigureTestServices(s => s.AddSingleton<IChatProvider>(provider));
        }).CreateClient();

        var response = await client.PostAsJsonAsync("/api/chat", new
        {
            messages = new[] { new { role = "user", content = "Hi" } },
        });
        Assert.Equal(HttpStatusCode.BadGateway, response.StatusCode);
    }

    [Fact]
    public async Task Provider_BuildsCorrectPayloadForChatCompletions()
    {
        var handler = new MockHttpMessageHandler
        {
            ResponseBody = """
                {
                  "id": "chatcmpl-abc",
                  "model": "gpt-4o-mini",
                  "choices": [
                    { "index": 0, "message": { "role": "assistant", "content": "Hello!" }, "finish_reason": "stop" }
                  ],
                  "usage": { "prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15 }
                }
                """,
        };
        var http = new HttpClient(handler) { BaseAddress = new Uri("https://api.openai.com/v1/") };
        var provider = new OpenAiCompatibleChatProvider(http);

        var response = await provider.CompleteAsync(new ChatRequest
        {
            Messages = new List<ChatMessage> { new ChatMessage { Role = "user", Content = "Hi" } },
            Model = "gpt-4o-mini",
            Temperature = 0.7,
            MaxTokens = 1024,
        });

        Assert.Equal("chatcmpl-abc", response.Id);
        Assert.Equal("Hello!", response.Choices[0].Content);
        Assert.Equal(15, response.Usage!.TotalTokens);

        Assert.NotNull(handler.RequestUri);
        Assert.EndsWith("/v1/chat/completions", handler.RequestUri);
        Assert.NotNull(handler.RequestBody);
        Assert.Contains("\"model\":\"gpt-4o-mini\"", handler.RequestBody);
        Assert.Contains("\"messages\"", handler.RequestBody);
        Assert.Contains("\"temperature\":0.7", handler.RequestBody);
        Assert.Contains("\"max_tokens\":1024", handler.RequestBody);
    }
}
