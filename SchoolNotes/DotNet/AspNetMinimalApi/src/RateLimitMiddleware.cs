using Microsoft.AspNetCore.Http;
using System.Threading.Tasks;

class RateLimitMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ICacheAdapter _cache;

    public RateLimitMiddleware(RequestDelegate next, ICacheAdapter cache)
    {
        _next = next;
        _cache = cache;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        int max = int.Parse(Environment.GetEnvironmentVariable("RATE_LIMIT_MAX") ?? "100");
        int window = int.Parse(Environment.GetEnvironmentVariable("RATE_LIMIT_WINDOW") ?? "60");

        string client = context.Connection.RemoteIpAddress?.ToString() ?? "anonymous";
        string key = "ratelimit:" + client;

        long count = await _cache.IncrementAsync(key, window);

        if (count > max)
        {
            context.Response.StatusCode = 429;
            await context.Response.WriteAsync("Rate limit exceeded");
            return;
        }

        await _next(context);
    }
}

static class RateLimitExtensions
{
    public static IApplicationBuilder UseRateLimit(this IApplicationBuilder app)
    {
        return app.UseMiddleware<RateLimitMiddleware>();
    }
}
