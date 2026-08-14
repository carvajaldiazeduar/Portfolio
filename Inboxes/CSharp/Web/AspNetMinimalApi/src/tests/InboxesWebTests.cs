using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace InboxesWeb.Tests;

public class InboxesWebTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public InboxesWebTests(WebApplicationFactory<Program> factory)
    {
        Environment.SetEnvironmentVariable("DB_DRIVER", "sqlite");
        Environment.SetEnvironmentVariable("DB_FILE", $"inboxes-test-{Guid.NewGuid():N}.db");
        _factory = factory.WithWebHostBuilder(_ => { });
        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task ListEmpty_ReturnsOk()
    {
        var res = await _client.GetAsync("/api/messages");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        var data = await res.Content.ReadFromJsonAsync<List<object>>();
        Assert.NotNull(data);
    }

    [Fact]
    public async Task SendMessage_CreatesMessage()
    {
        var res = await _client.PostAsJsonAsync("/api/messages", new
        {
            From = "alice",
            Subject = "Hello",
            Body = "World"
        });
        Assert.Equal(HttpStatusCode.Created, res.StatusCode);
        var msg = await res.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(msg);
        Assert.Equal("alice", msg["from"].ToString());
        Assert.Equal("Hello", msg["subject"].ToString());
    }

    [Fact]
    public async Task ListMessages_ReturnsAll()
    {
        await _client.PostAsJsonAsync("/api/messages", new { From = "a", Subject = "s1", Body = "b1" });
        await _client.PostAsJsonAsync("/api/messages", new { From = "b", Subject = "s2", Body = "b2" });
        var res = await _client.GetAsync("/api/messages");
        var msgs = await res.Content.ReadFromJsonAsync<List<object>>();
        Assert.Equal(2, msgs!.Count);
    }

    [Fact]
    public async Task ReadMessage_MarksAsRead()
    {
        var post = await _client.PostAsJsonAsync("/api/messages", new { From = "a", Subject = "s", Body = "b" });
        var created = await post.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        var id = int.Parse(created!["id"].ToString()!);
        var res = await _client.GetAsync($"/api/messages/{id}");
        var msg = await res.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.Equal("True", msg!["read"].ToString());
    }

    [Fact]
    public async Task ReadNonexistent_Returns404()
    {
        var res = await _client.GetAsync("/api/messages/999");
        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    [Fact]
    public async Task DeleteMessage_RemovesIt()
    {
        var post = await _client.PostAsJsonAsync("/api/messages", new { From = "a", Subject = "s", Body = "b" });
        var created = await post.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        var id = int.Parse(created!["id"].ToString()!);
        var del = await _client.DeleteAsync($"/api/messages/{id}");
        Assert.Equal(HttpStatusCode.NoContent, del.StatusCode);
        var list = await _client.GetAsync("/api/messages");
        var msgs = await list.Content.ReadFromJsonAsync<List<object>>();
        Assert.Empty(msgs!);
    }

    [Fact]
    public async Task DeleteNonexistent_Returns404()
    {
        var res = await _client.DeleteAsync("/api/messages/999");
        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    [Fact]
    public async Task ListAfterDelete_ShowsRemaining()
    {
        await _client.PostAsJsonAsync("/api/messages", new { From = "a", Subject = "keep", Body = "me" });
        var post2 = await _client.PostAsJsonAsync("/api/messages", new { From = "b", Subject = "del", Body = "this" });
        var created = await post2.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        var id = int.Parse(created!["id"].ToString()!);
        await _client.DeleteAsync($"/api/messages/{id}");
        var list = await _client.GetAsync("/api/messages");
        var msgs = await list.Content.ReadFromJsonAsync<List<Dictionary<string, object>>>();
        Assert.Single(msgs!);
        Assert.Equal("keep", msgs![0]["subject"].ToString());
    }
}
