using System.Collections.Concurrent;

class LocalCache : ICacheAdapter
{
    private readonly ConcurrentDictionary<string, (string value, DateTime expiry)> _store = new();

    public async Task<string> GetAsync(string key)
    {
        (string value, DateTime expiry) item;
        if (_store.TryGetValue(key, out item) && item.expiry > DateTime.UtcNow)
        {
            await Task.CompletedTask;
            return item.value;
        }

        _store.TryRemove(key, out _);
        await Task.CompletedTask;

        return null;
    }

    public async Task SetAsync(string key, string value, int ttlSeconds)
    {
        _store[key] = (value, DateTime.UtcNow.AddSeconds(ttlSeconds));
        await Task.CompletedTask;
    }

    public async Task RemoveAsync(string key)
    {
        _store.TryRemove(key, out _);
        await Task.CompletedTask;
    }

    public async Task RemoveByPrefixAsync(string prefix)
    {
        foreach (string key in _store.Keys.Where(k => k.StartsWith(prefix, StringComparison.Ordinal)))
            _store.TryRemove(key, out _);
        await Task.CompletedTask;
    }

    public async Task<long> IncrementAsync(string key, int ttlSeconds)
    {
        DateTime expiry = DateTime.UtcNow.AddSeconds(ttlSeconds);
        (string value, DateTime expiry) result = _store.AddOrUpdate(key,
            ("1", expiry),
            (_, old) =>
            {
                if (old.expiry <= DateTime.UtcNow)
                {
                    return ("1", expiry);
                }
                long next = long.Parse(old.value) + 1;
                return (next.ToString(), expiry);
            });
        await Task.CompletedTask;
        return long.Parse(result.value);
    }
}
