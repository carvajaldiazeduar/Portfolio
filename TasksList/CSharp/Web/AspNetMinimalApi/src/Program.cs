using System.Text.Json;
using Microsoft.EntityFrameworkCore;

var driver = (Environment.GetEnvironmentVariable("DB_DRIVER") ?? "postgresql").ToLower();

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<TasksListDbContext>(options => DatabaseConfig.Configure(options, driver, "tasks"));
builder.Services.AddSingleton<ICacheAdapter>(CacheFactory.Create());
builder.Services.AddScoped<TaskService>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    if (driver != "mongodb")
        scope.ServiceProvider.GetRequiredService<TasksListDbContext>().Database.EnsureCreated();
}

app.UseStaticFiles();

app.MapGet("/", () => Results.File("wwwroot/index.html", "text/html"));

app.MapGet("/api/tasks", (TaskService service, ICacheAdapter cache) =>
{
    var cached = cache.Get("tasks:all");
    if (cached != null) return Results.Ok(JsonSerializer.Deserialize<List<TaskItem>>(cached));
    var list = service.GetAll();
    cache.Set("tasks:all", JsonSerializer.Serialize(list));
    return Results.Ok(list);
});

app.MapPost("/api/tasks", (JsonElement body, TaskService service) =>
{
    var title = body.GetProperty("title").GetString();
    if (string.IsNullOrWhiteSpace(title)) return Results.BadRequest(new { error = "Title is required" });
    var description = body.TryGetProperty("description", out var d) ? d.GetString() ?? "" : "";
    var task = service.Create(title, description);
    return Results.Created($"/api/tasks/{task.Id}", task);
});

app.MapPut("/api/tasks/{id:int}/complete", (int id, TaskService service) =>
{
    if (!service.Complete(id)) return Results.NotFound(new { error = "Task not found" });
    return Results.Ok(new { success = true });
});

app.MapDelete("/api/tasks/{id:int}", (int id, TaskService service) =>
{
    if (!service.Delete(id)) return Results.NotFound(new { error = "Task not found" });
    return Results.Ok(new { success = true });
});

app.Run();

public partial class Program { }