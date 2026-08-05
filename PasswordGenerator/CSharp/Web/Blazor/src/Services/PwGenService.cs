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
        var chars = "";
        if (useUpper) chars += Upper;
        if (useLower) chars += Lower;
        if (useDigits) chars += Digits;
        if (useSymbols) chars += Symbols;
        if (chars == "") throw new ArgumentException("Select at least one character type");
        var pw = new string(Enumerable.Range(0, length).Select(_ => chars[Random.Shared.Next(chars.Length)]).ToArray());
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