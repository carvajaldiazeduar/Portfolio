namespace ConversorCli;

public static class Conversor
{
    private static readonly Dictionary<string, Dictionary<string, double>> Conversion = new()
    {
        ["length"] = new()
        {
            ["m"] = 1.0,
            ["km"] = 0.001,
            ["mi"] = 0.000621371,
            ["ft"] = 3.28084,
            ["in"] = 39.3701,
            ["cm"] = 100.0,
        },
        ["weight"] = new()
        {
            ["kg"] = 1.0,
            ["g"] = 1000.0,
            ["lb"] = 2.20462,
            ["oz"] = 35.274,
            ["mg"] = 1000000.0,
        },
        ["temperature"] = new()
        {
            ["C"] = 0,
            ["F"] = 0,
            ["K"] = 0,
        },
    };

    public static readonly Dictionary<string, string[]> CategoryUnits = new()
    {
        ["length"] = new[] { "m", "km", "mi", "ft", "in", "cm" },
        ["weight"] = new[] { "kg", "g", "lb", "oz", "mg" },
        ["temperature"] = new[] { "C", "F", "K" },
    };

    public static string[] ListCategories() => Conversion.Keys.ToArray();

    public static double Convert(double value, string fromUnit, string toUnit)
    {
        foreach (var (category, units) in Conversion)
        {
            if (!units.ContainsKey(fromUnit) || !units.ContainsKey(toUnit))
                continue;

            if (category == "temperature")
                return ConvertTemperature(value, fromUnit, toUnit);

            double factorFrom = units[fromUnit];
            double factorTo = units[toUnit];
            return value / factorFrom * factorTo;
        }

        throw new InvalidOperationException($"Incompatible units: {fromUnit} -> {toUnit}");
    }

    private static double ConvertTemperature(double value, string from, string to)
    {
        if (from == to) return value;

        return (from, to) switch
        {
            ("C", "F") => value * 9.0 / 5.0 + 32,
            ("C", "K") => value + 273.15,
            ("F", "C") => (value - 32) * 5.0 / 9.0,
            ("F", "K") => (value - 32) * 5.0 / 9.0 + 273.15,
            ("K", "C") => value - 273.15,
            ("K", "F") => (value - 273.15) * 9.0 / 5.0 + 32,
            _ => throw new InvalidOperationException($"Invalid temperature conversion: {from} -> {to}"),
        };
    }
}
