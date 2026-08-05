using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace CalculatorWeb.Tests;

public class CalculatorWebTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public CalculatorWebTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Index_ReturnsSuccess()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/");
        response.EnsureSuccessStatusCode();
    }

    [Theory]
    [InlineData("add", 2, 3, 5)]
    [InlineData("subtract", 5, 3, 2)]
    [InlineData("multiply", 2, 3, 6)]
    public async Task Calculate_ValidOperations_ReturnsCorrectResult(string op, double a, double b, double expected)
    {
        var client = _factory.CreateClient();
        var response = await client.PostAsJsonAsync("/calculate", new { A = a.ToString(), B = b.ToString(), Operator = op });
        var data = await response.Content.ReadFromJsonAsync<Dictionary<string, double>>();
        Assert.Equal(expected, data!["result"]);
    }

    [Fact]
    public async Task DivideByZero_ReturnsBadRequest()
    {
        var client = _factory.CreateClient();
        var response = await client.PostAsJsonAsync("/calculate", new { A = "5", B = "0", Operator = "divide" });
        Assert.Equal(System.Net.HttpStatusCode.BadRequest, response.StatusCode);
    }
}
