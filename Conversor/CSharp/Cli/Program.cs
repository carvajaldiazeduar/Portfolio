namespace ConversorCli;

class Program
{
    static void Main(string[] args)
    {
        Console.WriteLine("=== Unit Converter ===");

        while (true)
        {
            Console.WriteLine("\nCategories:");
            var cats = Conversor.ListCategories();
            for (int i = 0; i < cats.Length; i++)
                Console.WriteLine($"  {i + 1}. {cats[i]}");
            Console.WriteLine("  0. Exit");
            Console.Write("Select category: ");

            var input = Console.ReadLine();
            if (input == "0") { Console.WriteLine("Goodbye!"); break; }

            if (!int.TryParse(input, out int choice) || choice < 1 || choice > cats.Length)
            {
                Console.WriteLine("Invalid choice");
                continue;
            }

            var category = cats[choice - 1];
            var units = Conversor.CategoryUnits[category];

            Console.WriteLine($"\nUnits ({category}):");
            for (int i = 0; i < units.Length; i++)
                Console.WriteLine($"  {i + 1}. {units[i]}");

            Console.Write("Select from unit: ");
            if (!int.TryParse(Console.ReadLine(), out int fromIdx) || fromIdx < 1 || fromIdx > units.Length)
            { Console.WriteLine("Invalid"); continue; }

            Console.Write("Select to unit: ");
            if (!int.TryParse(Console.ReadLine(), out int toIdx) || toIdx < 1 || toIdx > units.Length)
            { Console.WriteLine("Invalid"); continue; }

            Console.Write("Enter value: ");
            if (!double.TryParse(Console.ReadLine(), out double value))
            { Console.WriteLine("Invalid number"); continue; }

            try
            {
                var result = Conversor.Convert(value, units[fromIdx - 1], units[toIdx - 1]);
                Console.WriteLine($"\nResult: {value} {units[fromIdx - 1]} = {result} {units[toIdx - 1]}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
            }
        }
    }
}
