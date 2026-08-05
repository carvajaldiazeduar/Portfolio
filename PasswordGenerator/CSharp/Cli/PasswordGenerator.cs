namespace PasswordGeneratorCli;

public static class PasswordGenerator
{
    private const string Upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    private const string Lower = "abcdefghijklmnopqrstuvwxyz";
    private const string Digits = "0123456789";
    private const string Symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?";

    public static string Generate(int length = 16, bool useUpper = true, bool useLower = true,
        bool useDigits = true, bool useSymbols = true)
    {
        if (length < 1)
            throw new ArgumentException("Password length must be at least 1");

        var categories = new List<string>();
        if (useUpper) categories.Add(Upper);
        if (useLower) categories.Add(Lower);
        if (useDigits) categories.Add(Digits);
        if (useSymbols) categories.Add(Symbols);

        if (categories.Count == 0)
            throw new ArgumentException("At least one character category must be enabled");

        if (length < categories.Count)
            throw new ArgumentException(
                $"Password length must be at least {categories.Count} " +
                $"when {categories.Count} categories are enabled");

        var rng = Random.Shared;
        var passwordChars = new char[length];
        var index = 0;

        foreach (var cat in categories)
            passwordChars[index++] = cat[rng.Next(cat.Length)];

        var allChars = string.Concat(categories);
        while (index < length)
            passwordChars[index++] = allChars[rng.Next(allChars.Length)];

        rng.Shuffle(passwordChars);
        return new string(passwordChars);
    }
}
