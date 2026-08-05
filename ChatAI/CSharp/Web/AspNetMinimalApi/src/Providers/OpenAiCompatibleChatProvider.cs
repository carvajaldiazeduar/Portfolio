using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.Json.Serialization;

public class OpenAiCompatibleChatProvider : IChatProvider
{
    private readonly HttpClient _http;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    public OpenAiCompatibleChatProvider(HttpClient? http = null)
    {
        var baseUrl = Environment.GetEnvironmentVariable("OPENAI_BASE_URL") ?? "https://api.openai.com/v1";
        var apiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY") ?? "";
        _http = http ?? new HttpClient { BaseAddress = new Uri(baseUrl.TrimEnd('/') + "/") };
        if (!string.IsNullOrEmpty(apiKey))
            _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
    }

    public async Task<ChatResponse> CompleteAsync(ChatRequest request)
    {
        var model = request.Model ?? Environment.GetEnvironmentVariable("CHAT_MODEL") ?? "gpt-4o-mini";
        var temperature = request.Temperature ?? (double.TryParse(Environment.GetEnvironmentVariable("CHAT_TEMPERATURE"), out var t) ? t : 0.7);
        var maxTokens = request.MaxTokens ?? (int.TryParse(Environment.GetEnvironmentVariable("CHAT_MAX_TOKENS"), out var mt) ? mt : 1024);

        var payload = new
        {
            model,
            messages = request.Messages!.Select(m => new { role = m.Role, content = m.Content }),
            temperature,
            max_tokens = maxTokens,
        };

        using var response = await _http.PostAsJsonAsync("chat/completions", payload);
        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"Provider error {(int)response.StatusCode}: {errorBody}");
        }

        var body = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<OpenAiCompletionResponse>(body, JsonOptions);
        var choice = data?.Choices?.FirstOrDefault();

        return new ChatResponse
        {
            Id = data?.Id ?? "",
            Model = data?.Model ?? model,
            Choices = new List<ChatChoice>
            {
                new ChatChoice
                {
                    Role = choice?.Message?.Role ?? "assistant",
                    Content = choice?.Message?.Content ?? "",
                },
            },
            Usage = new ChatUsage
            {
                PromptTokens = data?.Usage?.PromptTokens ?? 0,
                CompletionTokens = data?.Usage?.CompletionTokens ?? 0,
                TotalTokens = data?.Usage?.TotalTokens ?? 0,
            },
        };
    }

    private class OpenAiCompletionResponse
    {
        [JsonPropertyName("id")]
        public string Id { get; set; } = "";

        [JsonPropertyName("model")]
        public string Model { get; set; } = "";

        [JsonPropertyName("choices")]
        public List<OpenAiChoice>? Choices { get; set; }

        [JsonPropertyName("usage")]
        public OpenAiUsage? Usage { get; set; }
    }

    private class OpenAiChoice
    {
        [JsonPropertyName("message")]
        public OpenAiMessage? Message { get; set; }
    }

    private class OpenAiMessage
    {
        [JsonPropertyName("role")]
        public string Role { get; set; } = "";

        [JsonPropertyName("content")]
        public string Content { get; set; } = "";
    }

    private class OpenAiUsage
    {
        [JsonPropertyName("prompt_tokens")]
        public int PromptTokens { get; set; }

        [JsonPropertyName("completion_tokens")]
        public int CompletionTokens { get; set; }

        [JsonPropertyName("total_tokens")]
        public int TotalTokens { get; set; }
    }
}
