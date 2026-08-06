using System.Text.Json;
using Microsoft.EntityFrameworkCore;

var driver = (Environment.GetEnvironmentVariable("DB_DRIVER") ?? "postgresql").ToLower();

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<ContactsDbContext>(options => DatabaseConfig.Configure(options, driver, "contacts"));
builder.Services.AddSingleton<ICacheAdapter>(CacheFactory.Create());
builder.Services.AddScoped<ContactService>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    if (driver != "mongodb")
        scope.ServiceProvider.GetRequiredService<ContactsDbContext>().Database.EnsureCreated();
}

app.UseStaticFiles();

app.MapGet("/api/contacts", (ContactService service, ICacheAdapter cache) =>
{
    var cached = cache.Get("contacts:all");
    if (cached != null) return Results.Ok(JsonSerializer.Deserialize<List<Contact>>(cached));
    var list = service.GetAll();
    cache.Set("contacts:all", JsonSerializer.Serialize(list));
    return Results.Ok(list);
});

app.MapPost("/api/contacts", (JsonElement body, ContactService service) =>
{
    var name = body.GetProperty("name").GetString();
    if (string.IsNullOrWhiteSpace(name))
        return Results.BadRequest(new { error = "Name is required" });
    var phone = body.TryGetProperty("phone", out var p) ? p.GetString() ?? "" : "";
    var email = body.TryGetProperty("email", out var e) ? e.GetString() ?? "" : "";
    var contact = service.Create(name, phone, email);
    return Results.Created($"/api/contacts/{contact.Id}", contact);
});

app.MapGet("/api/contacts/search", (string? q, ContactService service, ICacheAdapter cache) =>
{
    var query = q?.ToLower() ?? "";
    var cacheKey = $"contacts:search:{query}";
    var cached = cache.Get(cacheKey);
    if (cached != null) return Results.Ok(JsonSerializer.Deserialize<List<Contact>>(cached));
    var list = service.Search(query);
    cache.Set(cacheKey, JsonSerializer.Serialize(list));
    return Results.Ok(list);
});

app.MapDelete("/api/contacts/{id:int}", (int id, ContactService service) =>
{
    if (!service.Delete(id)) return Results.NotFound(new { error = "Not found" });
    return Results.Ok(new { message = "Deleted" });
});

app.MapFallbackToFile("index.html");

app.MapGet("/swagger", () => Results.Redirect("/swagger.html"));

app.Run();

public partial class Program { }
