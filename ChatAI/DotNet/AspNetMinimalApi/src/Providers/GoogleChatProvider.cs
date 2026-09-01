using System.Text.Json;

public class GoogleChatProvider : IChatProvider
{
    private readonly HttpClient _http;
    private readonly string _apiKey;
    private readonly bool _ownsHttp;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public GoogleChatProvider(string baseUrl, string apiKey, int timeoutMs, HttpClient? http = null)
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
    }

    public async Task<ChatResponse> CompleteAsync(ChatRequest request)
    {
        var model = request.Model ?? Env("CHAT_MODEL", "gpt-4o-mini");
        var temperature = request.Temperature ?? DoubleEnv("CHAT_TEMPERATURE", 0.7);
        var maxTokens = request.MaxTokens ?? IntEnv("CHAT_MAX_TOKENS", 1024);

        var contents = new List<object>();
        foreach (var m in request.Messages!)
        {
            var role = string.Equals(m.Role, "user", StringComparison.OrdinalIgnoreCase) ? "user"
                : string.Equals(m.Role, "assistant", StringComparison.OrdinalIgnoreCase) ? "model"
                : "user";
            contents.Add(new
            {
                role = role,
                parts = new[] { new { text = m.Content } }
            });
        }

        var payload = new
        {
            contents = contents,
            generationConfig = new
            {
                temperature = temperature,
                maxOutputTokens = maxTokens
            }
        };

        var baseAddr = _http.BaseAddress?.ToString()?.TrimEnd('/') ?? Env("GOOGLE_BASE_URL", "https://generativelanguage.googleapis.com").TrimEnd('/');
        var url = $"{baseAddr}/v1beta/models/{model}:generateContent?key={_apiKey}";

        try
        {
            var response = await _http.PostAsync(new Uri(url), new StringContent(JsonSerializer.Serialize(payload), System.Text.Encoding.UTF8, "application/json"));
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                throw new ProviderCallException($"Provider error {(int)response.StatusCode}: {errorBody}");
            }
            var body = await response.Content.ReadAsStringAsync();
            return ParseGoogleResponse(body, model);
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

    private ChatResponse ParseGoogleResponse(string? body, string model)
    {
        var resp = new ChatResponse { Model = model, Provider = "google" };
        if (string.IsNullOrEmpty(body))
        {
            resp.Choices = new List<ChatChoice> { EmptyChoice() };
            resp.Usage = new ChatUsage();
            return resp;
        }
        try
        {
            var data = JsonSerializer.Deserialize<GoogleCompletionResponse>(body, JsonOptions);
            var outChoices = new List<ChatChoice>();
            foreach (var c in data?.Candidates ?? Enumerable.Empty<GoogleCandidate>())
            {
                if (c.Content != null && c.Content.Parts != null)
                {
                    var text = string.Concat(c.Content.Parts.Where(p => p.Text != null).Select(p => p.Text));
                    outChoices.Add(new ChatChoice { Role = c.Content.Role ?? "model", Content = text });
                }
            }
            if (outChoices.Count == 0)
                outChoices.Add(EmptyChoice());
            resp.Choices = outChoices;

            var usage = data?.UsageMetadata;
            resp.Usage = new ChatUsage
            {
                PromptTokens = usage?.PromptTokens ?? 0,
                CompletionTokens = usage?.CandidatesTokens ?? 0,
                TotalTokens = usage?.TotalTokens ?? 0,
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

    private class GoogleCompletionResponse
    {
        public List<GoogleCandidate>? Candidates { get; set; }
        public GoogleUsage? UsageMetadata { get; set; }
    }

    private class GoogleCandidate
    {
        public GoogleContent? Content { get; set; }
    }

    private class GoogleContent
    {
        public string? Role { get; set; }
        public List<GooglePart>? Parts { get; set; }
    }

    private class GooglePart
    {
        public string? Text { get; set; }
    }

    private class GoogleUsage
    {
        public int PromptTokens { get; set; }
        public int CandidatesTokens { get; set; }
        public int TotalTokens { get; set; }
    }
}
