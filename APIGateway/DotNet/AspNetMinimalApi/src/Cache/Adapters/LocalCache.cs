using System.Collections.Concurrent;
using System.Threading.Tasks;

class LocalCache : ICacheAdapter
{
    private readonly ConcurrentDictionary<string, (string value, DateTime expiry)> _store = new();

    public Task<string> GetAsync(string key)
    {
        if (_store.TryGetValue(key, out (string value, DateTime expiry) item) && item.expiry > DateTime.UtcNow)
            return Task.FromResult(item.value);
        _store.TryRemove(key, out _);
        return Task.FromResult<string>(null);
    }

    public Task SetAsync(string key, string value, int ttlSeconds)
    {
        _store[key] = (value, DateTime.UtcNow.AddSeconds(ttlSeconds));
        return Task.CompletedTask;
    }

    public Task RemoveAsync(string key)
    {
        _store.TryRemove(key, out _);
        return Task.CompletedTask;
    }

    public Task<long> IncrementAsync(string key, int ttlSeconds)
    {
        DateTime expiry = DateTime.UtcNow.AddSeconds(ttlSeconds);
        (string value, DateTime expiry) result = _store.AddOrUpdate(key,
            ("1", expiry),
            (_, old) =>
            {
                if (old.expiry <= DateTime.UtcNow)
                    return ("1", expiry);
                return ((long.Parse(old.value) + 1).ToString(), expiry);
            });
        return Task.FromResult(long.Parse(result.value));
    }

    public Task ClearAsync()
    {
        _store.Clear();
        return Task.CompletedTask;
    }
}