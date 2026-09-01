using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<ChatProviderFactory>();

var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapPost("/api/chat", async (ChatRequest request, ChatProviderFactory factory) =>
{
    if (request.Messages == null || request.Messages.Count == 0)
        return Results.BadRequest(new { error = "Messages must not be empty" });

    if (factory.RagEnabled())
    {
        var lastUser = request.Messages.LastOrDefault(m => m.Role == "user");
        if (lastUser != null)
        {
            var documents = await factory.RetrieveContextAsync(lastUser.Content ?? "");
            if (documents is { Count: > 0 })
            {
                var context = "Use the following context to answer the user's question:\n\n" +
                              string.Join("\n", documents.Select(d => "- " + d));
                request.Messages.Insert(0, new ChatMessage { Role = "system", Content = context });
            }
        }
    }

    var provider = factory.Resolve(request.Provider);

    IChatProvider primary;
    try
    {
        primary = factory.Create(provider);
    }
    catch (ProviderNotConfiguredException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
    catch (ArgumentException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }

    try
    {
        var response = await primary.CompleteAsync(request);
        response.Provider = provider;
        return Results.Ok(response);
    }
    catch (Exception ex)
    {
        var fallback = factory.FallbackProvider();
        if (!string.IsNullOrWhiteSpace(fallback))
        {
            try
            {
                var fb = factory.Create(fallback);
                var response = await fb.CompleteAsync(request);
                response.Provider = fallback;
                return Results.Ok(response);
            }
            catch (ProviderNotConfiguredException) { /* fallback not configured -> 502 */ }
            catch (ArgumentException) { /* fallback unsupported -> 502 */ }
            catch { /* fallback failed -> 502 */ }
        }
        return Results.Json(new { error = ex.Message }, statusCode: StatusCodes.Status502BadGateway);
    }
});

app.MapGet("/swagger", () => Results.Redirect("/swagger.html"));

app.Run();

public partial class Program { }

public class ChatMessage
{
    [JsonPropertyName("role")]
    public string Role { get; set; } = "";

    [JsonPropertyName("content")]
    public string Content { get; set; } = "";
}

public class ChatRequest
{
    [JsonPropertyName("messages")]
    public List<ChatMessage>? Messages { get; set; }

    [JsonPropertyName("provider")]
    public string? Provider { get; set; }

    [JsonPropertyName("model")]
    public string? Model { get; set; }

    [JsonPropertyName("temperature")]
    public double? Temperature { get; set; }

    [JsonPropertyName("max_tokens")]
    public int? MaxTokens { get; set; }
}

public class ChatChoice
{
    [JsonPropertyName("role")]
    public string Role { get; set; } = "";

    [JsonPropertyName("content")]
    public string Content { get; set; } = "";
}

public class ChatUsage
{
    [JsonPropertyName("prompt_tokens")]
    public int PromptTokens { get; set; }

    [JsonPropertyName("completion_tokens")]
    public int CompletionTokens { get; set; }

    [JsonPropertyName("total_tokens")]
    public int TotalTokens { get; set; }
}

public class ChatResponse
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("provider")]
    public string? Provider { get; set; }

    [JsonPropertyName("model")]
    public string Model { get; set; } = "";

    [JsonPropertyName("choices")]
    public List<ChatChoice> Choices { get; set; } = new();

    [JsonPropertyName("usage")]
    public ChatUsage? Usage { get; set; }
}
