using System.Text.Json;
using Microsoft.EntityFrameworkCore;

var driver = (Environment.GetEnvironmentVariable("DB_DRIVER") ?? "postgresql").ToLower();

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<PasswordGeneratorDbContext>(options => DatabaseConfig.Configure(options, driver, "passwords"));
builder.Services.AddSingleton<ICacheAdapter>(CacheFactory.Create());
builder.Services.AddScoped<PwGenService>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    if (driver != "mongodb")
        scope.ServiceProvider.GetRequiredService<PasswordGeneratorDbContext>().Database.EnsureCreated();
}

app.UseCors(c => c.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
app.UseStaticFiles();

app.MapPost("/api/generate", async (HttpContext context, PwGenService service) =>
{
    using var reader = new StreamReader(context.Request.Body);
    var body = await reader.ReadToEndAsync();
    int length = 16; bool useUpper = true, useLower = true, useDigits = true, useSymbols = false;
    if (!string.IsNullOrEmpty(body))
    {
        try
        {
            var json = JsonDocument.Parse(body);
            var root = json.RootElement;
            if (root.TryGetProperty("length", out var l)) length = l.GetInt32();
            if (root.TryGetProperty("use_upper", out var u)) useUpper = u.GetBoolean();
            if (root.TryGetProperty("use_lower", out var w)) useLower = w.GetBoolean();
            if (root.TryGetProperty("use_digits", out var d)) useDigits = d.GetBoolean();
            if (root.TryGetProperty("use_symbols", out var s)) useSymbols = s.GetBoolean();
        }
        catch { }
    }
    try
    {
        var password = service.Generate(length, useUpper, useLower, useDigits, useSymbols);
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsync(JsonSerializer.Serialize(new { password }));
    }
    catch (ArgumentException e)
    {
        context.Response.StatusCode = 400;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsync(JsonSerializer.Serialize(new { error = e.Message }));
    }
});

app.MapGet("/api/passwords", (PwGenService service, ICacheAdapter cache) =>
{
    var cached = cache.Get("passwords:recent");
    if (cached != null) return Results.Ok(JsonSerializer.Deserialize<List<PasswordEntry>>(cached));
    var list = service.GetHistory();
    cache.Set("passwords:recent", JsonSerializer.Serialize(list));
    return Results.Ok(list);
});

app.MapFallbackToFile("index.html");
app.Run();

public partial class Program { }