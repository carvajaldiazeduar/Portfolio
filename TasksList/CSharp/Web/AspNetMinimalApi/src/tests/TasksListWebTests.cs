using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace TasksListWeb.Tests;

public class TasksListWebTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public TasksListWebTests(WebApplicationFactory<Program> factory)
    {
        Environment.SetEnvironmentVariable("DB_DRIVER", "sqlite");
        Environment.SetEnvironmentVariable("DB_FILE", $"tasks-test-{Guid.NewGuid():N}.db");
        _factory = factory.WithWebHostBuilder(_ => { });
    }

    [Fact]
    public async Task Index_ReturnsSuccess()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/");
        response.EnsureSuccessStatusCode();
    }

    [Fact]
    public async Task AddAndListTasks()
    {
        var client = _factory.CreateClient();
        await client.PostAsJsonAsync("/api/tasks", new { Title = "Test", Description = "A task" });
        var tasks = await client.GetFromJsonAsync<List<Dictionary<string, object>>>("/api/tasks");
        Assert.NotEmpty(tasks!);
    }

    [Fact]
    public async Task CompleteTask_ReturnsOk()
    {
        var client = _factory.CreateClient();
        var post = await client.PostAsJsonAsync("/api/tasks", new { Title = "Test", Description = "" });
        var result = await post.Content.ReadFromJsonAsync<Dictionary<string, JsonElement>>();
        var id = result!["id"].GetInt32();
        var response = await client.PutAsync($"/api/tasks/{id}/complete", null);
        response.EnsureSuccessStatusCode();
    }
}
