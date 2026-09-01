using System;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

static class ProxyService
{
    private static readonly HttpClient Client = new();

    public static async Task ForwardAsync(HttpContext context, string service, string restPath)
    {
        string baseUrl = service switch
        {
            "users" => AppConfig.UsersServiceUrl,
            "orders" => AppConfig.OrdersServiceUrl,
            "products" => AppConfig.ProductsServiceUrl,
            _ => null
        };

        if (baseUrl == null)
        {
            context.Response.StatusCode = StatusCodes.Status404NotFound;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsync(JsonSerializer.Serialize(new { error = "Unknown service" }));
            return;
        }

        // Drop the leading slash from restPath
        string relative = restPath.TrimStart('/');
        string url = baseUrl.TrimEnd('/') + "/" + relative;

        using HttpRequestMessage request = new(new HttpMethod(context.Request.Method), url);
        if (context.Request.ContentLength > 0 && context.Request.Body != null)
        {
            request.Content = new StreamContent(context.Request.Body);
        }

        try
        {
            using HttpResponseMessage upstream = await Client.SendAsync(request);
            string body = await upstream.Content.ReadAsStringAsync();
            context.Response.StatusCode = (int)upstream.StatusCode;
            context.Response.ContentType = upstream.Content.Headers.ContentType?.ToString()
                ?? "application/json";
            await context.Response.WriteAsync(body);
        }
        catch (HttpRequestException)
        {
            context.Response.StatusCode = StatusCodes.Status502BadGateway;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsync(JsonSerializer.Serialize(new
            {
                error = "Bad Gateway",
                message = "Upstream service unavailable"
            }));
        }
    }
}