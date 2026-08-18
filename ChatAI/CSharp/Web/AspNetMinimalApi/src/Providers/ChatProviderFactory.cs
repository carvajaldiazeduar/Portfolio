using System.Net.Http.Headers;
using System.Text.Json;

public class ProviderCallException : Exception
{
    public ProviderCallException(string message) : base(message) { }
}

public class ProviderNotConfiguredException : Exception
{
    public string Provider { get; }

    public ProviderNotConfiguredException(string provider)
        : base($"Provider '{provider}' is not configured (missing API key)")
    {
        Provider = provider;
    }
}

public class ChatProviderFactory
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private static readonly HttpClient RagClient = new();

    public virtual string Resolve(string? requested)
    {
        if (!string.IsNullOrWhiteSpace(requested))
            return requested;
        return Environment.GetEnvironmentVariable("CHAT_PROVIDER") ?? "openai";
    }

    public virtual string? FallbackProvider()
    {
        var fb = Environment.GetEnvironmentVariable("CHAT_FALLBACK_PROVIDER");
        return string.IsNullOrWhiteSpace(fb) ? null : fb;
    }

    public virtual int TimeoutMs()
    {
        var raw = Environment.GetEnvironmentVariable("CHAT_TIMEOUT_MS") ?? "30000";
        return int.TryParse(raw, out var v) ? v : 30000;
    }

    public virtual bool RagEnabled()
    {
        var raw = Environment.GetEnvironmentVariable("RAG_ENABLED");
        return raw is "1" or "true" or "TRUE" or "yes";
    }

    public virtual string RagSearchUrl() =>
        Env("RAG_SEARCH_URL", "http://semantic-search:5000/api/search");

    public virtual int RagTopK()
    {
        var raw = Environment.GetEnvironmentVariable("RAG_TOP_K") ?? "3";
        return int.TryParse(raw, out var v) ? v : 3;
    }

    public virtual async Task<List<string>?> RetrieveContextAsync(string query)
    {
        try
        {
            RagClient.Timeout = TimeSpan.FromMilliseconds(TimeoutMs());
            var url = $"{RagSearchUrl()}?q={Uri.EscapeDataString(query)}&k={RagTopK()}";
            var response = await RagClient.GetAsync(url);
            if (!response.IsSuccessStatusCode)
                return null;
            var body = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(body);
            if (!doc.RootElement.TryGetProperty("results", out var results))
                return null;
            var documents = new List<string>();
            foreach (var item in results.EnumerateArray())
            {
                if (item.TryGetProperty("document", out var document) &&
                    !string.IsNullOrWhiteSpace(document.GetString()))
                    documents.Add(document.GetString()!);
            }
            return documents;
        }
        catch
        {
            return null;
        }
    }

    public virtual string? KeyFor(string provider) => provider switch
    {
        "openai" or "openai-compatible" => Environment.GetEnvironmentVariable("OPENAI_API_KEY"),
        "azure" => Environment.GetEnvironmentVariable("AZURE_OPENAI_API_KEY"),
        "google" => Environment.GetEnvironmentVariable("GOOGLE_API_KEY"),
        "anthropic" => Environment.GetEnvironmentVariable("ANTHROPIC_API_KEY"),
        _ => null,
    };

    public virtual string BaseUrlFor(string provider) => provider switch
    {
        "openai" or "openai-compatible" =>
            Env("OPENAI_BASE_URL", "https://api.openai.com/v1"),
        "azure" =>
            Env("AZURE_OPENAI_ENDPOINT", "https://api.openai.com/v1"),
        "google" =>
            Env("GOOGLE_BASE_URL", "https://generativelanguage.googleapis.com"),
        "anthropic" =>
            Env("ANTHROPIC_BASE_URL", "https://api.anthropic.com"),
        _ => throw new ArgumentException($"Unsupported provider: {provider}"),
    };

    public virtual string DeploymentFor(string provider) =>
        provider == "azure" ? Env("AZURE_OPENAI_DEPLOYMENT", "gpt-4o-mini") : null!;

    public virtual IChatProvider Create(string provider)
    {
        var key = KeyFor(provider);
        if (string.IsNullOrWhiteSpace(key))
            throw new ProviderNotConfiguredException(provider);

        var url = BaseUrlFor(provider);
        var timeoutMs = TimeoutMs();

        return provider switch
        {
            "openai" or "openai-compatible" => new OpenAiCompatibleChatProvider(url, key, timeoutMs),
            "azure" => new AzureChatProvider(url, key, DeploymentFor("azure")!, timeoutMs),
            "google" => new GoogleChatProvider(url, key, timeoutMs),
            "anthropic" => new AnthropicChatProvider(url, key, timeoutMs),
            _ => throw new ArgumentException($"Unsupported provider: {provider}"),
        };
    }

    private static string Env(string name, string fallback)
    {
        var v = Environment.GetEnvironmentVariable(name);
        return string.IsNullOrWhiteSpace(v) ? fallback : v;
    }
}
