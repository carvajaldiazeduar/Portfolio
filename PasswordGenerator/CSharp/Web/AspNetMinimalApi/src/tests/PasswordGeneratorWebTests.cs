using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace PasswordGeneratorWeb.Tests;

public class PasswordGeneratorWebTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public PasswordGeneratorWebTests(WebApplicationFactory<Program> factory)
    {
        Environment.SetEnvironmentVariable("DB_DRIVER", "sqlite");
        Environment.SetEnvironmentVariable("DB_FILE", $"passwords-test-{Guid.NewGuid():N}.db");
        _factory = factory.WithWebHostBuilder(_ => { });
    }

    [Fact]
    public async Task GetIndex_ReturnsHtml()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("text/html", response.Content.Headers.ContentType?.MediaType);
    }

    [Fact]
    public async Task GenerateDefault_Returns16Chars()
    {
        var client = _factory.CreateClient();
        var content = new StringContent("{}", Encoding.UTF8, "application/json");
        var response = await client.PostAsync("/api/generate", content);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var json = await response.Content.ReadAsStringAsync();
        var doc = JsonDocument.Parse(json);
        var password = doc.RootElement.GetProperty("password").GetString()!;
        Assert.Equal(16, password.Length);
    }

    [Fact]
    public async Task GenerateCustomLength()
    {
        var client = _factory.CreateClient();
        var payload = JsonSerializer.Serialize(new { length = 24 });
        var content = new StringContent(payload, Encoding.UTF8, "application/json");
        var response = await client.PostAsync("/api/generate", content);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var json = await response.Content.ReadAsStringAsync();
        var doc = JsonDocument.Parse(json);
        var password = doc.RootElement.GetProperty("password").GetString()!;
        Assert.Equal(24, password.Length);
    }

    [Fact]
    public async Task GenerateNoUppercase()
    {
        var client = _factory.CreateClient();
        var payload = JsonSerializer.Serialize(new { use_upper = false });
        var content = new StringContent(payload, Encoding.UTF8, "application/json");
        var response = await client.PostAsync("/api/generate", content);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var json = await response.Content.ReadAsStringAsync();
        var doc = JsonDocument.Parse(json);
        var password = doc.RootElement.GetProperty("password").GetString()!;
        Assert.DoesNotMatch("[A-Z]", password);
    }

    [Fact]
    public async Task GenerateNoSymbols()
    {
        var client = _factory.CreateClient();
        var payload = JsonSerializer.Serialize(new { use_symbols = false });
        var content = new StringContent(payload, Encoding.UTF8, "application/json");
        var response = await client.PostAsync("/api/generate", content);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var json = await response.Content.ReadAsStringAsync();
        var doc = JsonDocument.Parse(json);
        var password = doc.RootElement.GetProperty("password").GetString()!;
        Assert.DoesNotMatch("[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?]", password);
    }

    [Fact]
    public async Task GenerateAllDisabled_ReturnsError()
    {
        var client = _factory.CreateClient();
        var payload = JsonSerializer.Serialize(new
        {
            use_upper = false, use_lower = false, use_digits = false, use_symbols = false
        });
        var content = new StringContent(payload, Encoding.UTF8, "application/json");
        var response = await client.PostAsync("/api/generate", content);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var json = await response.Content.ReadAsStringAsync();
        var doc = JsonDocument.Parse(json);
        Assert.True(doc.RootElement.TryGetProperty("error", out _));
    }

    [Fact]
    public async Task GenerateNegativeLength_ReturnsError()
    {
        var client = _factory.CreateClient();
        var payload = JsonSerializer.Serialize(new { length = -1 });
        var content = new StringContent(payload, Encoding.UTF8, "application/json");
        var response = await client.PostAsync("/api/generate", content);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GenerateAtLeastOneFromEachEnabled()
    {
        var client = _factory.CreateClient();
        var payload = JsonSerializer.Serialize(new
        {
            length = 20, use_upper = true, use_lower = true, use_digits = true, use_symbols = true
        });
        var content = new StringContent(payload, Encoding.UTF8, "application/json");
        var response = await client.PostAsync("/api/generate", content);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var json = await response.Content.ReadAsStringAsync();
        var doc = JsonDocument.Parse(json);
        var password = doc.RootElement.GetProperty("password").GetString()!;
        Assert.Matches("[A-Z]", password);
        Assert.Matches("[a-z]", password);
        Assert.Matches("[0-9]", password);
        Assert.Matches("[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?]", password);
    }
}
