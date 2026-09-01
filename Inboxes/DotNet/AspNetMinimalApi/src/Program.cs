using System.Text.Json;
using Microsoft.EntityFrameworkCore;

var driver = (Environment.GetEnvironmentVariable("DB_DRIVER") ?? "postgresql").ToLower();

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<InboxesDbContext>(options => DatabaseConfig.Configure(options, driver, "inboxes"));
builder.Services.AddSingleton<ICacheAdapter>(CacheFactory.Create());
builder.Services.AddScoped<MessageService>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    if (driver != "mongodb")
        scope.ServiceProvider.GetRequiredService<InboxesDbContext>().Database.EnsureCreated();
}

app.UseDefaultFiles();
app.UseStaticFiles();

app.MapGet("/api/messages", (MessageService service, ICacheAdapter cache) =>
{
    var cached = cache.Get("messages:all");
    if (cached != null) return Results.Ok(JsonSerializer.Deserialize<List<Message>>(cached));
    var list = service.GetAll();
    cache.Set("messages:all", JsonSerializer.Serialize(list));
    return Results.Ok(list);
});

app.MapPost("/api/messages", (JsonElement body, MessageService service) =>
{
    var subject = body.GetProperty("subject").GetString();
    if (string.IsNullOrWhiteSpace(subject)) return Results.BadRequest(new { error = "Subject is required" });
    var sender = body.TryGetProperty("from", out var s) ? s.GetString() ?? "" : "";
    var msgBody = body.TryGetProperty("body", out var b) ? b.GetString() ?? "" : "";
    var msg = service.Create(sender, subject, msgBody);
    return Results.Created($"/api/messages/{msg.Id}", msg);
});

app.MapGet("/api/messages/{id:int}", (int id, MessageService service, ICacheAdapter cache) =>
{
    var cached = cache.Get($"message:{id}");
    if (cached != null) return Results.Ok(JsonSerializer.Deserialize<Message>(cached));
    var msg = service.GetById(id);
    if (msg == null) return Results.NotFound(new { error = "Not found" });
    cache.Set($"message:{id}", JsonSerializer.Serialize(msg));
    cache.Delete("messages:all");
    return Results.Ok(msg);
});

app.MapDelete("/api/messages/{id:int}", (int id, MessageService service) =>
{
    if (!service.Delete(id)) return Results.NotFound(new { error = "Not found" });
    return Results.NoContent();
});

app.MapGet("/swagger", () => Results.Redirect("/swagger.html"));

app.Run();

public partial class Program { }