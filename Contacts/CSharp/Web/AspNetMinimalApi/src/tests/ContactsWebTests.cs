using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace ContactsWeb.Tests;

public class ContactDto
{
    public string? Name { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
}

public class ContactsWebTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public ContactsWebTests(WebApplicationFactory<Program> factory)
    {
        Environment.SetEnvironmentVariable("DB_DRIVER", "sqlite");
        Environment.SetEnvironmentVariable("DB_FILE", $"contacts-test-{Guid.NewGuid():N}.db");
        _factory = factory.WithWebHostBuilder(_ => { });
        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task GetContacts_ReturnsEmptyList()
    {
        var response = await _client.GetAsync("/api/contacts");
        response.EnsureSuccessStatusCode();
        var contacts = await response.Content.ReadFromJsonAsync<List<Contact>>();
        Assert.NotNull(contacts);
        Assert.Empty(contacts);
    }

    [Fact]
    public async Task AddContact_ReturnsCreated()
    {
        var dto = new ContactDto { Name = "Alice", Phone = "123", Email = "a@b.com" };
        var response = await _client.PostAsJsonAsync("/api/contacts", dto);
        Assert.Equal(201, (int)response.StatusCode);
        var contact = await response.Content.ReadFromJsonAsync<Contact>();
        Assert.NotNull(contact);
        Assert.Equal("Alice", contact!.Name);
    }

    [Fact]
    public async Task AddContact_MissingName_ReturnsBadRequest()
    {
        var dto = new ContactDto { Phone = "123" };
        var response = await _client.PostAsJsonAsync("/api/contacts", dto);
        Assert.Equal(400, (int)response.StatusCode);
    }

    [Fact]
    public async Task SearchContacts_ReturnsFiltered()
    {
        await _client.PostAsJsonAsync("/api/contacts", new ContactDto { Name = "Alice", Phone = "123", Email = "a@b.com" });
        await _client.PostAsJsonAsync("/api/contacts", new ContactDto { Name = "Bob", Phone = "456", Email = "b@c.com" });
        var response = await _client.GetAsync("/api/contacts/search?q=ali");
        response.EnsureSuccessStatusCode();
        var contacts = await response.Content.ReadFromJsonAsync<List<Contact>>();
        Assert.NotNull(contacts);
        var list = contacts!.ToList();
        Assert.Single(list);
        Assert.Equal("Alice", list[0].Name);
    }

    [Fact]
    public async Task DeleteContact_ValidIndex_RemovesContact()
    {
        var post = await _client.PostAsJsonAsync("/api/contacts", new ContactDto { Name = "Alice", Phone = "123", Email = "a@b.com" });
        var created = await post.Content.ReadFromJsonAsync<Contact>();
        var response = await _client.DeleteAsync($"/api/contacts/{created!.Id}");
        response.EnsureSuccessStatusCode();
        var getResponse = await _client.GetAsync("/api/contacts");
        var contacts = await getResponse.Content.ReadFromJsonAsync<List<Contact>>();
        Assert.NotNull(contacts);
        Assert.Empty(contacts!);
    }

    [Fact]
    public async Task DeleteContact_InvalidIndex_ReturnsNotFound()
    {
        var response = await _client.DeleteAsync("/api/contacts/99");
        Assert.Equal(404, (int)response.StatusCode);
    }
}
