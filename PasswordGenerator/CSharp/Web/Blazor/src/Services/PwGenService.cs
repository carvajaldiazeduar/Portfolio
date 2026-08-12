using System.Text.Json;
using Microsoft.EntityFrameworkCore;

public class PwGenService
{
    private readonly PasswordGeneratorDbContext _db;
    private readonly ICacheAdapter _cache;
    private const string Upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    private const string Lower = "abcdefghijklmnopqrstuvwxyz";
    private const string Digits = "0123456789";
    private const string Symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?";

    public PwGenService(PasswordGeneratorDbContext db, ICacheAdapter cache)
    {
        _db = db;
        _cache = cache;
    }

    public string Generate(int length, bool useUpper, bool useLower, bool useDigits, bool useSymbols)
    {
        var categories = new List<string>();
        if (useUpper) categories.Add(Upper);
        if (useLower) categories.Add(Lower);
        if (useDigits) categories.Add(Digits);
        if (useSymbols) categories.Add(Symbols);
        if (categories.Count == 0)
            throw new ArgumentException("Select at least one character type");
        if (length < categories.Count)
            throw new ArgumentException(
                $"Password length must be at least {categories.Count} when {categories.Count} categories are enabled");

        var rng = Random.Shared;
        var passwordChars = new char[length];
        var index = 0;
        foreach (var cat in categories)
            passwordChars[index++] = cat[rng.Next(cat.Length)];
        var allChars = string.Concat(categories);
        while (index < length)
            passwordChars[index++] = allChars[rng.Next(allChars.Length)];
        rng.Shuffle(passwordChars);
        var pw = new string(passwordChars);

        var entry = new PasswordEntry { Password = pw, Length = length, CreatedAt = DateTime.UtcNow.ToString("o") };
        _db.PasswordEntries.Add(entry);
        _db.SaveChanges();
        _cache.Delete("passwords:recent");
        return pw;
    }

    public List<PasswordEntry> GetHistory()
    {
        var cached = _cache.Get("passwords:recent");
        if (cached != null)
            return JsonSerializer.Deserialize<List<PasswordEntry>>(cached)!;
        var list = _db.PasswordEntries.OrderByDescending(p => p.Id).Take(50).ToList();
        _cache.Set("passwords:recent", JsonSerializer.Serialize(list));
        return list;
    }
}