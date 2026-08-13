using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace ChatAI.Tests;

public class FakeChatProvider : IChatProvider
{
    public ChatResponse? Response { get; set; }
    public bool ThrowOnCall { get; set; }
    public int FailFirstN { get; set; }
    public string FailureMessage { get; set; } = "upstream provider failed";
    public ChatRequest? LastRequest { get; set; }
    public int CallCount { get; set; }

    public Task<ChatResponse> CompleteAsync(ChatRequest request)
    {
        LastRequest = request;
        CallCount++;
        if (ThrowOnCall || CallCount <= FailFirstN)
            throw new InvalidOperationException(FailureMessage);
        return Task.FromResult(Response ?? new ChatResponse
        {
            Id = "chatcmpl-test",
            Model = "gpt-4o-mini",
            Provider = "openai",
            Choices = new List<ChatChoice> { new ChatChoice { Role = "assistant", Content = "Hello!" } },
            Usage = new ChatUsage { PromptTokens = 5, CompletionTokens = 3, TotalTokens = 8 },
        });
    }
}

public class FakeChatProviderFactory : ChatProviderFactory
{
    public string? ResolvedOverride { get; set; }
    public string? FallbackOverride { get; set; }
    public IChatProvider? ProviderInstance { get; set; }
    public string? ThrowOnCreateProvider { get; set; }

    public override string Resolve(string? requested) =>
        !string.IsNullOrWhiteSpace(requested) ? requested : (ResolvedOverride ?? base.Resolve(requested));

    public override string? FallbackProvider() => FallbackOverride;

    public override IChatProvider Create(string provider)
    {
        if (provider == ThrowOnCreateProvider)
            throw new ProviderNotConfiguredException(provider);
        return ProviderInstance!;
    }

    public override int TimeoutMs() => 30000;
}

public class StubHttpMessageHandler : HttpMessageHandler
{
    public string? RequestUri { get; private set; }
    public string? RequestBody { get; private set; }
    public string? CapturedAuth { get; private set; }
    public HttpStatusCode StatusCode { get; set; } = HttpStatusCode.OK;
    public string ResponseBody { get; set; } = "";

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        RequestUri = request.RequestUri?.ToString();
        RequestBody = request.Content != null ? await request.Content.ReadAsStringAsync(cancellationToken) : null;
        CapturedAuth = request.Headers.Authorization?.ToString();
        var apikey = request.Headers.FirstOrDefault(h => h.Key == "api-key").Value?.FirstOrDefault();
        if (string.IsNullOrEmpty(CapturedAuth) && apikey != null)
            CapturedAuth = "api-key " + apikey;
        return new HttpResponseMessage(StatusCode)
        {
            Content = new StringContent(ResponseBody, Encoding.UTF8, "application/json"),
        };
    }
}

public class SlowHttpMessageHandler : HttpMessageHandler
{
    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        return Task.Delay(TimeSpan.FromDays(1), cancellationToken).ContinueWith(_ => new HttpResponseMessage(HttpStatusCode.OK));
    }
}

public class ChatAITests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ChatAITests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    private HttpClient ClientWithFactory(FakeChatProviderFactory factory) => _factory
        .WithWebHostBuilder(b => b.ConfigureTestServices(s => s.AddSingleton<ChatProviderFactory>(factory)))
        .CreateClient();

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
        var factory = new FakeChatProviderFactory { ProviderInstance = provider, ResolvedOverride = "openai" };
        var client = ClientWithFactory(factory);

        var response = await client.PostAsJsonAsync("/api/chat", new
        {
            messages = new[] { new { role = "user", content = "Hi" } },
        });

        response.EnsureSuccessStatusCode();
        var data = await response.Content.ReadFromJsonAsync<ChatResponse>();
        Assert.Equal("assistant", data!.Choices[0].Role);
        Assert.Equal("Hello!", data.Choices[0].Content);
        Assert.Equal("chatcmpl-test", data.Id);
        Assert.Equal("openai", data.Provider);
    }

    [Fact]
    public async Task Chat_ClientOverridesModelAndMaxTokens()
    {
        var provider = new FakeChatProvider();
        var factory = new FakeChatProviderFactory { ProviderInstance = provider, ResolvedOverride = "openai" };
        var client = ClientWithFactory(factory);

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
        var factory = new FakeChatProviderFactory { ProviderInstance = provider, ResolvedOverride = "openai" };
        var client = ClientWithFactory(factory);

        var response = await client.PostAsJsonAsync("/api/chat", new
        {
            messages = new[] { new { role = "user", content = "Hi" } },
        });
        Assert.Equal(HttpStatusCode.BadGateway, response.StatusCode);
    }

    [Fact]
    public async Task Provider_BuildsCorrectPayloadForChatCompletions()
    {
        var handler = new StubHttpMessageHandler
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
        var provider = new OpenAiCompatibleChatProvider("https://api.openai.com/v1", "test-key", 5000, http);

        var response = await provider.CompleteAsync(new ChatRequest
        {
            Messages = new List<ChatMessage> { new ChatMessage { Role = "user", Content = "Hi" } },
            Model = "gpt-4o-mini",
            Temperature = 0.7,
            MaxTokens = 1024,
        });

        Assert.Equal("chatcmpl-abc", response.Id);
        Assert.Equal("openai", response.Provider);
        Assert.Equal("Hello!", response.Choices[0].Content);
        Assert.Equal(15, response.Usage!.TotalTokens);

        Assert.NotNull(handler.RequestUri);
        Assert.EndsWith("/v1/chat/completions", handler.RequestUri);
        Assert.NotNull(handler.RequestBody);
        Assert.Contains("\"model\":\"gpt-4o-mini\"", handler.RequestBody);
        Assert.Contains("\"messages\"", handler.RequestBody);
        Assert.Contains("\"temperature\":0.7", handler.RequestBody);
        Assert.Contains("\"max_tokens\":1024", handler.RequestBody);
        Assert.Equal("Bearer test-key", handler.CapturedAuth);
    }

    [Fact]
    public async Task OpenAi_ProviderTimeout_ThrowsFast()
    {
        var handler = new SlowHttpMessageHandler();
        var http = new HttpClient(handler) { BaseAddress = new Uri("https://api.openai.com/v1/") };
        var provider = new OpenAiCompatibleChatProvider("https://api.openai.com/v1", "test-key", 300, http);

        await Assert.ThrowsAsync<ProviderCallException>(async () => await provider.CompleteAsync(new ChatRequest
        {
            Messages = new List<ChatMessage> { new ChatMessage { Role = "user", Content = "Hi" } },
        }));
    }

    // --- Hot-switch / multi-provider / tolerance ---

    [Fact]
    public async Task RequestProviderOverridesEnv()
    {
        var provider = new FakeChatProvider
        {
            Response = new ChatResponse
            {
                Id = "chatcmpl-azure",
                Provider = "azure",
                Choices = new List<ChatChoice> { new ChatChoice { Role = "assistant", Content = "from azure" } },
                Usage = new ChatUsage(),
            },
        };
        var factory = new FakeChatProviderFactory { ProviderInstance = provider, ResolvedOverride = "azure" };
        var client = ClientWithFactory(factory);

        var response = await client.PostAsJsonAsync("/api/chat", new
        {
            messages = new[] { new { role = "user", content = "Hi" } },
            provider = "azure",
        });

        response.EnsureSuccessStatusCode();
        var data = await response.Content.ReadFromJsonAsync<ChatResponse>();
        Assert.Equal("azure", data!.Provider);
        Assert.Equal("from azure", data.Choices[0].Content);
    }

    [Fact]
    public async Task ConfiguredProviderMissingKey_ReturnsBadRequest()
    {
        var factory = new FakeChatProviderFactory
        {
            ThrowOnCreateProvider = "azure",
            ProviderInstance = new FakeChatProvider(),
        };
        var client = ClientWithFactory(factory);

        var response = await client.PostAsJsonAsync("/api/chat", new
        {
            messages = new[] { new { role = "user", content = "Hi" } },
            provider = "azure",
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var data = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Provider 'azure' is not configured (missing API key)", data.GetProperty("error").GetString());
    }

    [Fact]
    public async Task FallbackOnFailure_Returns200()
    {
        var provider = new FakeChatProvider
        {
            FailFirstN = 1,
            Response = new ChatResponse
            {
                Id = "chatcmpl-fb",
                Choices = new List<ChatChoice> { new ChatChoice { Role = "assistant", Content = "fallback ok" } },
                Usage = new ChatUsage(),
            },
        };
        var factory = new FakeChatProviderFactory
        {
            ProviderInstance = provider,
            ResolvedOverride = "openai",
            FallbackOverride = "azure",
        };
        var client = ClientWithFactory(factory);

        var response = await client.PostAsJsonAsync("/api/chat", new
        {
            messages = new[] { new { role = "user", content = "Hi" } },
        });

        response.EnsureSuccessStatusCode();
        var data = await response.Content.ReadFromJsonAsync<ChatResponse>();
        Assert.Equal("azure", data!.Provider);
        Assert.Equal("fallback ok", data.Choices[0].Content);
    }

    [Fact]
    public async Task FallbackMissingKey_Returns502()
    {
        var provider = new FakeChatProvider { ThrowOnCall = true };
        var factory = new FakeChatProviderFactory
        {
            ProviderInstance = provider,
            ResolvedOverride = "openai",
            FallbackOverride = "azure",
            ThrowOnCreateProvider = "azure",
        };
        var client = ClientWithFactory(factory);

        var response = await client.PostAsJsonAsync("/api/chat", new
        {
            messages = new[] { new { role = "user", content = "Hi" } },
        });
        Assert.Equal(HttpStatusCode.BadGateway, response.StatusCode);
    }

    [Fact]
    public async Task ProviderTimeoutThroughController_Returns502()
    {
        var provider = new FakeChatProvider
        {
            ThrowOnCall = true,
            FailureMessage = "Read timed out: CHAT_TIMEOUT_MS exceeded",
        };
        var factory = new FakeChatProviderFactory
        {
            ProviderInstance = provider,
            ResolvedOverride = "openai",
        };
        var client = ClientWithFactory(factory);

        var response = await client.PostAsJsonAsync("/api/chat", new
        {
            messages = new[] { new { role = "user", content = "Hi" } },
        });
        Assert.Equal(HttpStatusCode.BadGateway, response.StatusCode);
        var data = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Contains("CHAT_TIMEOUT_MS", data.GetProperty("error").GetString());
    }
}
