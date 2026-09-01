using System;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<ICacheAdapter>(CacheFactory.Create());

WebApplication app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

app.UseGatewayMiddleware();

app.MapGet("/health", () => Results.Json(new
{
    status = "ok",
    timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
}));

app.MapPost("/auth/login", async (HttpContext ctx) =>
{
    JsonDocument doc = null;
    string username = null;
    string password = null;
    try
    {
        doc = await JsonDocument.ParseAsync(ctx.Request.Body);
        if (doc.RootElement.TryGetProperty("username", out JsonElement u))
            username = u.GetString();
        if (doc.RootElement.TryGetProperty("password", out JsonElement p))
            password = p.GetString();
    }
    catch
    {
        // invalid json
    }
    finally
    {
        doc?.Dispose();
    }

    if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
        return Results.Json(new { error = "Username and password required" },
            statusCode: StatusCodes.Status400BadRequest);

    object result = AuthService.Login(username, password);
    if (result == null)
        return Results.Json(new { error = "Invalid credentials" },
            statusCode: StatusCodes.Status401Unauthorized);

    return Results.Json(result);
});

app.MapGet("/swagger", () => Results.Redirect("/swagger.html"));

app.MapMethods("/api/{service}/{**rest}", new[] { "GET", "POST", "PUT", "DELETE", "PATCH" },
    async (string service, string rest, HttpContext ctx) =>
    {
        if (service == "users" || service == "orders" || service == "products")
        {
            await ProxyService.ForwardAsync(ctx, service, rest ?? "");
            return;
        }
        ctx.Response.StatusCode = StatusCodes.Status404NotFound;
    });

app.Run();

public partial class Program { }