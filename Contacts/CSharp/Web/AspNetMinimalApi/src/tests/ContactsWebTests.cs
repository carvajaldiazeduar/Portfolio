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

public class ErrorResponse
{
    public Dictionary<string, string>? Errors { get; set; }
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
        var dto = new ContactDto { Name = "Alice", Phone = "123-4567", Email = "a@b.com" };
        var response = await _client.PostAsJsonAsync("/api/contacts", dto);
        Assert.Equal(201, (int)response.StatusCode);
        var contact = await response.Content.ReadFromJsonAsync<Contact>();
        Assert.NotNull(contact);
        Assert.Equal("Alice", contact!.Name);
    }

    [Fact]
    public async Task AddContact_TrimsInputs()
    {
        var dto = new ContactDto { Name = "  Alice  ", Phone = " 123-4567 ", Email = " a@b.com " };
        var response = await _client.PostAsJsonAsync("/api/contacts", dto);
        Assert.Equal(201, (int)response.StatusCode);
        var contact = await response.Content.ReadFromJsonAsync<Contact>();
        Assert.NotNull(contact);
        Assert.Equal("Alice", contact!.Name);
        Assert.Equal("123-4567", contact.Phone);
        Assert.Equal("a@b.com", contact.Email);
    }

    [Fact]
    public async Task AddContact_MissingName_ReturnsBadRequestWithNameError()
    {
        var dto = new ContactDto { Phone = "123-4567", Email = "a@b.com" };
        var response = await _client.PostAsJsonAsync("/api/contacts", dto);
        Assert.Equal(400, (int)response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ErrorResponse>();
        Assert.NotNull(body?.Errors);
        Assert.Equal("Name is required", body.Errors["name"]);
    }

    [Fact]
    public async Task AddContact_InvalidName_ReturnsBadRequestWithNameError()
    {
        var dto = new ContactDto { Name = "Al1ce", Phone = "123-4567", Email = "a@b.com" };
        var response = await _client.PostAsJsonAsync("/api/contacts", dto);
        Assert.Equal(400, (int)response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ErrorResponse>();
        Assert.NotNull(body?.Errors);
        Assert.True(body.Errors.ContainsKey("name"));
    }

    [Fact]
    public async Task AddContact_InvalidPhone_ReturnsBadRequestWithPhoneError()
    {
        var dto = new ContactDto { Name = "Alice", Phone = "12", Email = "a@b.com" };
        var response = await _client.PostAsJsonAsync("/api/contacts", dto);
        Assert.Equal(400, (int)response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ErrorResponse>();
        Assert.NotNull(body?.Errors);
        Assert.True(body.Errors.ContainsKey("phone"));
        Assert.False(body.Errors.ContainsKey("email"));
        Assert.False(body.Errors.ContainsKey("name"));
    }

    [Fact]
    public async Task AddContact_InvalidEmail_ReturnsBadRequestWithEmailError()
    {
        var dto = new ContactDto { Name = "Alice", Phone = "123-4567", Email = "invalid-email" };
        var response = await _client.PostAsJsonAsync("/api/contacts", dto);
        Assert.Equal(400, (int)response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ErrorResponse>();
        Assert.NotNull(body?.Errors);
        Assert.Equal("Invalid email format", body.Errors["email"]);
    }

    [Fact]
    public async Task SearchContacts_ReturnsFiltered()
    {
        await _client.PostAsJsonAsync("/api/contacts", new ContactDto { Name = "Alice", Phone = "123-4567", Email = "a@b.com" });
        await _client.PostAsJsonAsync("/api/contacts", new ContactDto { Name = "Bob", Phone = "456-7890", Email = "b@c.com" });
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
        var post = await _client.PostAsJsonAsync("/api/contacts", new ContactDto { Name = "Alice", Phone = "123-4567", Email = "a@b.com" });
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
