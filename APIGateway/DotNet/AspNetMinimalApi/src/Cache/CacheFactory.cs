using System;

static class CacheFactory
{
    public static ICacheAdapter Create()
    {
        string type = Environment.GetEnvironmentVariable("CACHE_TYPE") ?? "redis";
        if (type.Equals("local", StringComparison.OrdinalIgnoreCase))
            return new LocalCache();
        string host = Environment.GetEnvironmentVariable("REDIS_HOST") ?? "localhost:6379";
        try
        {
            return new RedisCache(host);
        }
        catch
        {
            return new LocalCache();
        }
    }
}