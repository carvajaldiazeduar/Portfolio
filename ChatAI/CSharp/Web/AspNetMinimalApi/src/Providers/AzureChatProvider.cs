using System.Net.Http.Headers;
using System.Text.Json;

public class AzureChatProvider : IChatProvider
{
    private readonly HttpClient _http;
    private readonly string _apiKey;
    private readonly string _deployment;
    private readonly bool _ownsHttp;

    public AzureChatProvider(string endpoint, string apiKey, string deployment, int timeoutMs, HttpClient? http = null)
    {
        _apiKey = apiKey;
        _deployment = deployment;
        if (http == null)
        {
            _http = new HttpClient();
            _http.BaseAddress = new Uri(endpoint.TrimEnd('/'));
            _http.Timeout = TimeSpan.FromMilliseconds(timeoutMs);
            _ownsHttp = true;
        }
        else
        {
            _http = http;
        }
        _http.DefaultRequestHeaders.Add("api-key", _apiKey);
    }

    public async Task<ChatResponse> CompleteAsync(ChatRequest request)
    {
        var model = request.Model ?? Env("CHAT_MODEL", "gpt-4o-mini");
        var temperature = request.Temperature ?? DoubleEnv("CHAT_TEMPERATURE", 0.7);
        var maxTokens = request.MaxTokens ?? IntEnv("CHAT_MAX_TOKENS", 1024);
        var apiVersion = Env("AZURE_OPENAI_API_VERSION", "2024-06-01-preview");

        var payload = new
        {
            model,
            messages = request.Messages!.Select(m => new { role = m.Role, content = m.Content }),
            temperature,
            max_tokens = maxTokens,
        };

        var url = $"openai/deployments/{_deployment}/chat/completions?api-version={apiVersion}";

        try
        {
            using var httpRequest = new HttpRequestMessage(HttpMethod.Post, url)
            {
                Content = new StringContent(JsonSerializer.Serialize(payload), System.Text.Encoding.UTF8, "application/json")
            };
            var response = await _http.SendAsync(httpRequest);
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                throw new ProviderCallException($"Provider error {(int)response.StatusCode}: {errorBody}");
            }
            var body = await response.Content.ReadAsStringAsync();
            return OpenAiCompatibleChatProvider.ParseOpenAiResponse(body, model, "azure");
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
