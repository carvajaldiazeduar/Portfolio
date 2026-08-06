using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

var providerName = Environment.GetEnvironmentVariable("CHAT_PROVIDER") ?? "openai";

IChatProvider CreateProvider() => providerName switch
{
    _ => new OpenAiCompatibleChatProvider(),
};

builder.Services.AddSingleton<IChatProvider>(_ => CreateProvider());

var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapPost("/api/chat", async (ChatRequest request, IChatProvider provider) =>
{
    if (request.Messages == null || request.Messages.Count == 0)
        return Results.BadRequest(new { error = "Messages must not be empty" });

    try
    {
        var response = await provider.CompleteAsync(request);
        return Results.Ok(response);
    }
    catch (Exception ex)
    {
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

    [JsonPropertyName("model")]
    public string Model { get; set; } = "";

    [JsonPropertyName("choices")]
    public List<ChatChoice> Choices { get; set; } = new();

    [JsonPropertyName("usage")]
    public ChatUsage? Usage { get; set; }
}
