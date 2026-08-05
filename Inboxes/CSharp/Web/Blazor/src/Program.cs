using Microsoft.EntityFrameworkCore;

var driver = (Environment.GetEnvironmentVariable("DB_DRIVER") ?? "postgresql").ToLower();

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddRazorComponents().AddInteractiveServerComponents();
builder.Services.AddDbContext<InboxesDbContext>(options => DatabaseConfig.Configure(options, driver, "inboxes"));
builder.Services.AddSingleton<ICacheAdapter>(CacheFactory.Create());
builder.Services.AddScoped<MessageService>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    if (driver != "mongodb")
        scope.ServiceProvider.GetRequiredService<InboxesDbContext>().Database.EnsureCreated();
}

if (!app.Environment.IsDevelopment()) { app.UseExceptionHandler("/Error"); app.UseHsts(); }

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>().AddInteractiveServerRenderMode();
app.Run();

public partial class Program { }