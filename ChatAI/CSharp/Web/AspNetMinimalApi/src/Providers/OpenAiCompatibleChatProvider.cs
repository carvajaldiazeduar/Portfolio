using System.Net.Http.Headers;
using System.Text.Json;

public class OpenAiCompatibleChatProvider : IChatProvider
{
    private readonly HttpClient _http;
    private readonly string _apiKey;
    private readonly bool _ownsHttp;

    public OpenAiCompatibleChatProvider(string baseUrl, string apiKey, int timeoutMs, HttpClient? http = null)
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
        if (!string.IsNullOrEmpty(_apiKey))
            _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);
    }

    public async Task<ChatResponse> CompleteAsync(ChatRequest request)
    {
        var model = request.Model ?? Env("CHAT_MODEL", "gpt-4o-mini");
        var temperature = request.Temperature ?? DoubleEnv("CHAT_TEMPERATURE", 0.7);
        var maxTokens = request.MaxTokens ?? IntEnv("CHAT_MAX_TOKENS", 1024);

        var payload = new
        {
            model,
            messages = request.Messages!.Select(m => new { role = m.Role, content = m.Content }),
            temperature,
            max_tokens = maxTokens,
        };

        HttpResponseMessage response;
        try
        {
            response = await _http.PostAsJsonAsync("chat/completions", payload);
        }
        catch (TaskCanceledException ex)
        {
            throw new ProviderCallException("Provider error: " + (ex.Message ?? "timeout"));
        }
        catch (HttpRequestException ex)
        {
            throw new ProviderCallException("Provider error: " + (ex.Message ?? "request failed"));
        }

        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            throw new ProviderCallException($"Provider error {(int)response.StatusCode}: {errorBody}");
        }

        var body = await response.Content.ReadAsStringAsync();
        return ParseOpenAiResponse(body, model, "openai");
    }

    internal static ChatResponse ParseOpenAiResponse(string? body, string model, string provider)
    {
        var resp = new ChatResponse { Model = model, Provider = provider };
        if (string.IsNullOrEmpty(body))
        {
            resp.Id = "";
            resp.Choices = new List<ChatChoice> { EmptyChoice() };
            resp.Usage = new ChatUsage();
            return resp;
        }
        try
        {
            using var doc = JsonDocument.Parse(body);
            var root = doc.RootElement;

            resp.Id = root.TryGetProperty("id", out var id) ? (id.GetString() ?? "") : "";

            var choices = new List<ChatChoice>();
            if (root.TryGetProperty("choices", out var arr) && arr.ValueKind == JsonValueKind.Array && arr.GetArrayLength() > 0)
            {
                var first = arr[0];
                if (first.TryGetProperty("message", out var msg))
                {
                    choices.Add(new ChatChoice
                    {
                        Role = msg.TryGetProperty("role", out var r) ? (r.GetString() ?? "assistant") : "assistant",
                        Content = msg.TryGetProperty("content", out var c) ? (c.GetString() ?? "") : "",
                    });
                }
            }
            if (choices.Count == 0)
                choices.Add(EmptyChoice());
            resp.Choices = choices;

            resp.Usage = new ChatUsage();
            if (root.TryGetProperty("usage", out var u) && u.ValueKind == JsonValueKind.Object)
            {
                resp.Usage.PromptTokens = u.TryGetProperty("prompt_tokens", out var p) ? p.GetInt32() : 0;
                resp.Usage.CompletionTokens = u.TryGetProperty("completion_tokens", out var c) ? c.GetInt32() : 0;
                resp.Usage.TotalTokens = u.TryGetProperty("total_tokens", out var t) ? t.GetInt32() : 0;
            }
        }
        catch
        {
            resp.Id = "";
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
}
