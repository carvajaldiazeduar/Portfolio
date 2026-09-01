using System;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

class GatewayMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ICacheAdapter _cache;

    public GatewayMiddleware(RequestDelegate next, ICacheAdapter cache)
    {
        _next = next;
        _cache = cache;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        string path = context.Request.Path.Value ?? "";

        if (!path.StartsWith("/api/"))
        {
            await _next(context);
            return;
        }

        // 1. Auth (JWT)
        string authHeader = context.Request.Headers["Authorization"].ToString();
        if (string.IsNullOrEmpty(authHeader) || !authHeader.StartsWith("Bearer ", StringComparison.Ordinal))
        {
            await WriteErrorAsync(context, StatusCodes.Status401Unauthorized,
                "Missing or invalid Authorization header");
            return;
        }
        string token = authHeader.Substring(7);
        Dictionary<string, object> user = JwtUtil.Verify(token, AppConfig.JwtSecret);
        if (user == null)
        {
            await WriteErrorAsync(context, StatusCodes.Status401Unauthorized,
                "Invalid or expired token");
            return;
        }
        context.Items["user"] = user;

        // 2. Rate limit (per-IP, per-route)
        string prefix = ResolveRoute(path);
        int limit = AppConfig.RateLimitDefault;
        int window = AppConfig.RateLimitWindow;
        if (prefix == "/api/users") { limit = AppConfig.UsersLimit; window = 60; }
        else if (prefix == "/api/orders") { limit = AppConfig.OrdersLimit; window = 60; }
        else if (prefix == "/api/products") { limit = AppConfig.ProductsLimit; window = 60; }

        string clientIp = context.Connection.RemoteIpAddress?.ToString() ?? "anonymous";
        string key = $"ratelimit:{path}:{clientIp}";

        long current = await _cache.IncrementAsync(key, window);
        long remaining = Math.Max(0, limit - current);
        context.Response.Headers["X-RateLimit-Limit"] = limit.ToString();
        context.Response.Headers["X-RateLimit-Remaining"] = remaining.ToString();
        context.Response.Headers["X-RateLimit-Reset"] =
            (DateTimeOffset.UtcNow.ToUnixTimeSeconds() + window).ToString();

        if (current > limit)
        {
            await WriteErrorAsync(context, StatusCodes.Status429TooManyRequests,
                $"Rate limit exceeded. Limit: {limit} requests per {window}s");
            return;
        }

        await _next(context);
    }

    private static string ResolveRoute(string path)
    {
        if (path.StartsWith("/api/users")) return "/api/users";
        if (path.StartsWith("/api/orders")) return "/api/orders";
        if (path.StartsWith("/api/products")) return "/api/products";
        return path;
    }

    private static async Task WriteErrorAsync(HttpContext context, int status, string message)
    {
        context.Response.StatusCode = status;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsync(JsonSerializer.Serialize(new { error = message }));
    }
}

static class GatewayMiddlewareExtensions
{
    public static IApplicationBuilder UseGatewayMiddleware(this IApplicationBuilder app)
        => app.UseMiddleware<GatewayMiddleware>();
}