using ConversorCli;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseStaticFiles();

app.MapGet("/api/categories", () =>
{
    var cats = Conversor.ListCategories();
    var result = new Dictionary<string, string[]>();
    foreach (var cat in cats)
        result[cat] = Conversor.CategoryUnits[cat];
    return Results.Json(result);
});

app.MapPost("/api/convert", (ConvertRequest req) =>
{
    if (req.Value == null || string.IsNullOrEmpty(req.From) || string.IsNullOrEmpty(req.To))
        return Results.BadRequest(new { error = "Missing fields: value, from, to" });

    try
    {
        var result = Conversor.Convert(req.Value.Value, req.From, req.To);
        return Results.Json(new { result, from = req.From, to = req.To, value = req.Value.Value });
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

app.MapFallbackToFile("index.html");

app.Run();

public record ConvertRequest(double? Value, string? From, string? To);
public partial class Program { }
