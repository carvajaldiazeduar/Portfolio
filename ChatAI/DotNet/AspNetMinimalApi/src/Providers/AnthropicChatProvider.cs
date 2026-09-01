using System.Text.Json;

public class AnthropicChatProvider : IChatProvider
{
    private readonly HttpClient _http;
    private readonly string _apiKey;
    private readonly bool _ownsHttp;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public AnthropicChatProvider(string baseUrl, string apiKey, int timeoutMs, HttpClient? http = null)
    {
        _apiKey = apiKey;
        if (http == null)
        {
            _http = new HttpClient();
            _http.BaseAddress = new Uri(baseUrl.TrimEnd('/') + "/");
            _http.Timeout = TimeSpan.FromMilliseconds(timeoutMs);
            _ownsHttp = true;
        }
        else
        {
            _http = http;
        }
        _http.DefaultRequestHeaders.Add("x-api-key", _apiKey);
        _http.DefaultRequestHeaders.Add("anthropic-version", "2023-06-01");
    }

    public async Task<ChatResponse> CompleteAsync(ChatRequest request)
    {
        var model = request.Model ?? Env("CHAT_MODEL", "gpt-4o-mini");
        var temperature = request.Temperature ?? DoubleEnv("CHAT_TEMPERATURE", 0.7);
        var maxTokens = request.MaxTokens ?? IntEnv("CHAT_MAX_TOKENS", 1024);

        var messages = new List<object>();
        string? system = null;
        foreach (var m in request.Messages!)
        {
            if (string.Equals(m.Role, "system", StringComparison.OrdinalIgnoreCase))
            {
                system = m.Content;
                continue;
            }
            var role = string.Equals(m.Role, "assistant", StringComparison.OrdinalIgnoreCase) ? "assistant" : "user";
            messages.Add(new
            {
                role = role,
                content = m.Content
            });
        }

        var payload = new Dictionary<string, object>
        {
            ["model"] = model,
            ["messages"] = messages,
            ["max_tokens"] = maxTokens,
            ["temperature"] = temperature
        };
        if (system != null && !string.IsNullOrWhiteSpace(system))
            payload["system"] = system;

        try
        {
            var response = await _http.PostAsync("v1/messages", new StringContent(JsonSerializer.Serialize(payload), System.Text.Encoding.UTF8, "application/json"));
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                throw new ProviderCallException($"Provider error {(int)response.StatusCode}: {errorBody}");
            }
            var body = await response.Content.ReadAsStringAsync();
            return ParseAnthropicResponse(body, model);
        }
        catch (TaskCanceledException ex)
        {
            throw new ProviderCallException("Provider error: " + (ex.Message ?? "timeout"));
        }
        catch (HttpRequestException)
        {
            throw;
        }
    }

    private ChatResponse ParseAnthropicResponse(string? body, string model)
    {
        var resp = new ChatResponse { Model = model, Provider = "anthropic" };
        if (string.IsNullOrEmpty(body))
        {
            resp.Choices = new List<ChatChoice> { EmptyChoice() };
            resp.Usage = new ChatUsage();
            return resp;
        }
        try
        {
            var data = JsonSerializer.Deserialize<AnthropicCompletionResponse>(body, JsonOptions);
            var text = string.Concat((data?.Content ?? Enumerable.Empty<AnthropicContent>()).Where(c => c.Type == "text").Select(c => c.Text ?? ""));
            resp.Choices = new List<ChatChoice>
            {
                new ChatChoice { Role = "assistant", Content = text }
            };
            var usage = data?.Usage;
            var input = usage?.InputTokens ?? 0;
            var output = usage?.OutputTokens ?? 0;
            resp.Usage = new ChatUsage
            {
                PromptTokens = input,
                CompletionTokens = output,
                TotalTokens = input + output,
            };
        }
        catch
        {
            resp.Choices = new List<ChatChoice> { EmptyChoice() };
            resp.Usage = new ChatUsage();
        }
        return resp;
    }

    private static ChatChoice EmptyChoice() => new() { Role = "assistant", Content = "" };

    private static string Env(string name, string fallback)
    {
        var v = Environment.GetEnvironmentVariable(name);
        return string.IsNullOrWhiteSpace(v) ? fallback : v;
    }

    private static double DoubleEnv(string name, double fallback) =>
        double.TryParse(Environment.GetEnvironmentVariable(name), out var d) ? d : fallback;

    private static int IntEnv(string name, int fallback) =>
        int.TryParse(Environment.GetEnvironmentVariable(name), out var i) ? i : fallback;

    public void Dispose()
    {
        if (_ownsHttp) _http.Dispose();
    }

    private class AnthropicCompletionResponse
    {
        public List<AnthropicContent>? Content { get; set; }
        public AnthropicUsage? Usage { get; set; }
    }

    private class AnthropicContent
    {
        public string? Type { get; set; }
        public string? Text { get; set; }
    }

    private class AnthropicUsage
    {
        public int InputTokens { get; set; }
        public int OutputTokens { get; set; }
    }
}
