using CalculatorCli;

var operations = new Dictionary<string, (string name, string symbol)>
{
    ["1"] = ("Add", "+"),
    ["2"] = ("Subtract", "-"),
    ["3"] = ("Multiply", "*"),
    ["4"] = ("Divide", "/"),
};

while (true)
{
    Console.WriteLine("\n=== Simple Calculator ===");
    Console.WriteLine("1. Add");
    Console.WriteLine("2. Subtract");
    Console.WriteLine("3. Multiply");
    Console.WriteLine("4. Divide");
    Console.WriteLine("5. Exit");
    Console.Write("Choose an option (1-5): ");
    var choice = Console.ReadLine()?.Trim();

    if (choice == "5")
    {
        Console.WriteLine("Goodbye!");
        break;
    }

    if (!operations.ContainsKey(choice!))
    {
        Console.WriteLine("Invalid option. Please try again.");
        continue;
    }

    Console.Write("Enter first number: ");
    if (!double.TryParse(Console.ReadLine(), out var num1))
    {
        Console.WriteLine("Invalid input. Please enter a number.");
        continue;
    }

    Console.Write("Enter second number: ");
    if (!double.TryParse(Console.ReadLine(), out var num2))
    {
        Console.WriteLine("Invalid input. Please enter a number.");
        continue;
    }

    var op = operations[choice!];
    object? result = choice switch
    {
        "1" => Calculator.Add(num1, num2),
        "2" => Calculator.Subtract(num1, num2),
        "3" => Calculator.Multiply(num1, num2),
        "4" when num2 != 0 => Calculator.Divide(num1, num2).result,
        "4" => "Error: Cannot divide by zero",
        _ => "Invalid operation",
    };

    Console.WriteLine($"\n{num1} {op.symbol} {num2} = {result}");
}
