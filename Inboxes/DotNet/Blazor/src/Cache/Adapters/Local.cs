using System.Collections.Concurrent;

public class Local : ICacheAdapter
{
    private readonly ConcurrentDictionary<string, (string Value, DateTime Expiry)> _cache = new();

    public string? Get(string key)
    {
        if (_cache.TryGetValue(key, out var entry) && entry.Expiry > DateTime.UtcNow)
            return entry.Value;
        _cache.TryRemove(key, out _);
        return null;
    }

    public void Set(string key, string value, int ttl = 300)
    {
        _cache[key] = (value, DateTime.UtcNow.AddSeconds(ttl));
    }

    public void Delete(string key)
    {
        _cache.TryRemove(key, out _);
    }
}
