using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;

var driver = (Environment.GetEnvironmentVariable("DB_DRIVER") ?? "postgresql").ToLower();

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<ContactsDbContext>(options => DatabaseConfig.Configure(options, driver, "contacts"));
builder.Services.AddSingleton<ICacheAdapter>(CacheFactory.Create());
builder.Services.AddScoped<ContactService>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    if (driver != "mongodb")
        scope.ServiceProvider.GetRequiredService<ContactsDbContext>().Database.EnsureCreated();
}

app.UseStaticFiles();

app.MapGet("/api/contacts", (ContactService service, ICacheAdapter cache) =>
{
    var cached = cache.Get("contacts:all");
    if (cached != null) return Results.Ok(JsonSerializer.Deserialize<List<Contact>>(cached));
    var list = service.GetAll();
    cache.Set("contacts:all", JsonSerializer.Serialize(list));
    return Results.Ok(list);
});

app.MapPost("/api/contacts", (ContactInput input, ContactService service) =>
{
    var errors = ValidateContact(input);
    if (errors.Count > 0)
        return Results.BadRequest(new { errors });
    var contact = service.Create(input.Name!, input.Phone!, input.Email!);
    return Results.Created($"/api/contacts/{contact.Id}", contact);
});

app.MapGet("/api/contacts/search", (string? q, ContactService service, ICacheAdapter cache) =>
{
    var query = q?.ToLower() ?? "";
    var cacheKey = $"contacts:search:{query}";
    var cached = cache.Get(cacheKey);
    if (cached != null) return Results.Ok(JsonSerializer.Deserialize<List<Contact>>(cached));
    var list = service.Search(query);
    cache.Set(cacheKey, JsonSerializer.Serialize(list));
    return Results.Ok(list);
});

app.MapDelete("/api/contacts/{id:int}", (int id, ContactService service) =>
{
    if (!service.Delete(id)) return Results.NotFound(new { error = "Not found" });
    return Results.Ok(new { message = "Deleted" });
});

app.MapFallbackToFile("index.html");

app.MapGet("/swagger", () => Results.Redirect("/swagger.html"));

static Dictionary<string, string> ValidateContact(ContactInput input)
{
    input.Name = input.Name?.Trim() ?? "";
    input.Phone = input.Phone?.Trim() ?? "";
    input.Email = input.Email?.Trim() ?? "";

    var results = new List<ValidationResult>();
    var context = new ValidationContext(input);
    Validator.TryValidateObject(input, context, results, validateAllProperties: true);

    var errors = new Dictionary<string, string>();
    foreach (var result in results)
    {
        foreach (var member in result.MemberNames)
        {
            errors.TryAdd(JsonNamingPolicy.CamelCase.ConvertName(member), result.ErrorMessage ?? "");
        }
    }
    return errors;
}

app.Run();

public partial class Program { }
