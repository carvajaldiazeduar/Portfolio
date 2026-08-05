namespace PasswordGeneratorCli;

class Program
{
    static void Main(string[] args)
    {
        if (args.Length > 0)
        {
            int length = 16;
            bool useUpper = true, useLower = true, useDigits = true, useSymbols = true;

            for (int i = 0; i < args.Length; i++)
            {
                switch (args[i])
                {
                    case "-l":
                    case "--length" when i + 1 < args.Length:
                        int.TryParse(args[++i], out length);
                        break;
                    case "--no-upper":
                        useUpper = false;
                        break;
                    case "--no-lower":
                        useLower = false;
                        break;
                    case "--no-digits":
                        useDigits = false;
                        break;
                    case "--no-symbols":
                        useSymbols = false;
                        break;
                }
            }

            try
            {
                Console.WriteLine(PasswordGenerator.Generate(length, useUpper, useLower, useDigits, useSymbols));
            }
            catch (ArgumentException e)
            {
                Console.Error.WriteLine($"Error: {e.Message}");
                Environment.Exit(1);
            }
        }
        else
        {
            ShowMenu();
        }
    }

    static void ShowMenu()
    {
        Console.WriteLine("=== Password Generator ===");

        Console.Write("Length (default 16): ");
        var input = Console.ReadLine()?.Trim();
        int.TryParse(input, out int length);
        if (length < 1) length = 16;

        Console.Write("Include uppercase? (Y/n): ");
        var useUpper = Console.ReadLine()?.Trim().ToLower() != "n";

        Console.Write("Include lowercase? (Y/n): ");
        var useLower = Console.ReadLine()?.Trim().ToLower() != "n";

        Console.Write("Include digits? (Y/n): ");
        var useDigits = Console.ReadLine()?.Trim().ToLower() != "n";

        Console.Write("Include symbols? (Y/n): ");
        var useSymbols = Console.ReadLine()?.Trim().ToLower() != "n";

        try
        {
            var password = PasswordGenerator.Generate(length, useUpper, useLower, useDigits, useSymbols);
            Console.WriteLine($"\nGenerated password: {password}");
        }
        catch (ArgumentException e)
        {
            Console.WriteLine($"Error: {e.Message}");
        }
    }
}
