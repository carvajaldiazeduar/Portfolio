using CalculatorWeb;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseStaticFiles();

app.MapGet("/", () => Results.File("wwwroot/index.html", "text/html"));

app.MapPost("/calculate", (CalculateRequest request) =>
{
    var allowedOperators = new HashSet<string> { "add", "subtract", "multiply", "divide" };

    if (!allowedOperators.Contains(request.Operator))
        return Results.BadRequest(new { error = "Invalid operator" });

    try
    {
        var a = Convert.ToDouble(request.A);
        var b = Convert.ToDouble(request.B);

        double? result = request.Operator switch
        {
            "add" => a + b,
            "subtract" => a - b,
            "multiply" => a * b,
            "divide" when b != 0 => a / b,
            _ => null,
        };

        if (request.Operator == "divide" && b == 0)
            return Results.BadRequest(new { error = "Cannot divide by zero" });

        if (result == null)
            return Results.BadRequest(new { error = "Calculation error" });

        return Results.Ok(new { result });
    }
    catch
    {
        return Results.BadRequest(new { error = "Invalid number input" });
    }
});

app.Run();

public record CalculateRequest(string A, string B, string Operator);
