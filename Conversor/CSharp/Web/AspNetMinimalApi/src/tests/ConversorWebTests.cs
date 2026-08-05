using Xunit;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http.Json;
using System.Text.Json;

namespace ConversorWeb.Tests;

public class ConversorWebTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public ConversorWebTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task TestCategoriesEndpoint()
    {
        var resp = await _client.GetAsync("/api/categories");
        resp.EnsureSuccessStatusCode();
        var data = await resp.Content.ReadFromJsonAsync<Dictionary<string, string[]>>();
        Assert.NotNull(data);
        Assert.Contains("length", data!.Keys);
        Assert.Contains("weight", data.Keys);
        Assert.Contains("temperature", data.Keys);
    }

    [Fact]
    public async Task TestConvertLength()
    {
        var resp = await _client.PostAsJsonAsync("/api/convert", new { value = 1, from = "m", to = "cm" });
        resp.EnsureSuccessStatusCode();
        var data = await resp.Content.ReadFromJsonAsync<Dictionary<string, JsonElement>>();
        Assert.NotNull(data);
        Assert.True(Math.Abs(data!["result"].GetDouble() - 100) < 0.001);
    }

    [Fact]
    public async Task TestConvertTemperature()
    {
        var resp = await _client.PostAsJsonAsync("/api/convert", new { value = 0, from = "C", to = "F" });
        resp.EnsureSuccessStatusCode();
        var data = await resp.Content.ReadFromJsonAsync<Dictionary<string, JsonElement>>();
        Assert.NotNull(data);
        Assert.True(Math.Abs(data!["result"].GetDouble() - 32) < 0.001);
    }

    [Fact]
    public async Task TestConvertInvalid()
    {
        var resp = await _client.PostAsJsonAsync("/api/convert", new { value = 1, from = "m", to = "kg" });
        Assert.Equal(System.Net.HttpStatusCode.BadRequest, resp.StatusCode);
    }

    [Fact]
    public async Task TestConvertMissingFields()
    {
        var resp = await _client.PostAsJsonAsync("/api/convert", new { value = 1 });
        Assert.Equal(System.Net.HttpStatusCode.BadRequest, resp.StatusCode);
    }
}
