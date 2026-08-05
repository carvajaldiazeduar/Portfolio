using System.Net.Http.Json;

namespace TasksListWeb.Tests;

public class TasksListWebTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public TasksListWebTests(WebApplicationFactory<Program> factory)
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
        var result = await post.Content.ReadFromJsonAsync<Dictionary<string, int>>();
        var id = result!["id"];
        var response = await client.PutAsync($"/api/tasks/{id}/complete", null);
        response.EnsureSuccessStatusCode();
    }
}
