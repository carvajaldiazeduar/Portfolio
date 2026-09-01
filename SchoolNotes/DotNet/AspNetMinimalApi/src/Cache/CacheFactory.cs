using System;

static class CacheFactory
{
    public static ICacheAdapter Create()
    {
        string type = Environment.GetEnvironmentVariable("CACHE_TYPE") ?? "redis";
        string redisHost = Environment.GetEnvironmentVariable("REDIS_HOST") ?? "localhost:6379";
        if (type == "redis")
        {
            ICacheAdapter primary = new RedisCache(redisHost);
            LocalCache fallback = new LocalCache();
            return new CacheComposite(primary, fallback);
        }
        return new LocalCache();
    }
}

class CacheComposite : ICacheAdapter
{
    private readonly ICacheAdapter _primary;
    private readonly ICacheAdapter _fallback;

    public CacheComposite(ICacheAdapter primary, ICacheAdapter fallback)
    {
        _primary = primary;
        _fallback = fallback;
    }

    public async Task<string> GetAsync(string key)
    {
        try
        {
            string value = await _primary.GetAsync(key);
            if (value != null)
                return value;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error occurred while getting cache value for key '{key}': {ex.Message}");
        }
        return await _fallback.GetAsync(key);
    }

    public Task SetAsync(string key, string value, int ttlSeconds)
    {
        try { _primary.SetAsync(key, value, ttlSeconds); }
        catch (Exception ex) { Console.WriteLine($"Error setting cache '{key}': {ex.Message}"); }

        try { _fallback.SetAsync(key, value, ttlSeconds); }
        catch (Exception ex) { Console.WriteLine($"Error setting fallback cache '{key}': {ex.Message}"); }

        return Task.CompletedTask;
    }

    public Task RemoveAsync(string key)
    {
        try { _primary.RemoveAsync(key); }
        catch (Exception ex) { Console.WriteLine($"Error removing cache '{key}': {ex.Message}"); }

        try { _fallback.RemoveAsync(key); }
        catch (Exception ex) { Console.WriteLine($"Error removing fallback cache '{key}': {ex.Message}"); }

        return Task.CompletedTask;
    }

    public Task RemoveByPrefixAsync(string prefix)
    {
        try { _primary.RemoveByPrefixAsync(prefix); }
        catch (Exception ex) { Console.WriteLine($"Error removing cache prefix '{prefix}': {ex.Message}"); }

        try { _fallback.RemoveByPrefixAsync(prefix); }
        catch (Exception ex) { Console.WriteLine($"Error removing fallback cache prefix '{prefix}': {ex.Message}"); }

        return Task.CompletedTask;
    }

    public async Task<long> IncrementAsync(string key, int ttlSeconds)
    {
        long primaryResult = 0;
        long fallbackResult = 0;
        try
        {
            primaryResult = await _primary.IncrementAsync(key, ttlSeconds);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error occurred while incrementing cache value for key '{key}': {ex.Message}");
        }

        try
        {
            fallbackResult = await _fallback.IncrementAsync(key, ttlSeconds);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error occurred while incrementing fallback cache for key '{key}': {ex.Message}");
        }

        return primaryResult > 0 ? primaryResult : fallbackResult;
    }
}
