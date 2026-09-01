using StackExchange.Redis;

public class Redis : ICacheAdapter
{
    private readonly ConnectionMultiplexer? _redis;

    public Redis()
    {
        var redisHost = Environment.GetEnvironmentVariable("REDIS_HOST") ?? "localhost:6379";
        try { _redis = ConnectionMultiplexer.Connect(redisHost); } catch { }
    }

    public string? Get(string key)
    {
        if (_redis != null)
        {
            try
            {
                var val = _redis.GetDatabase().StringGet(key);
                if (val.HasValue) return val.ToString();
            }
            catch { }
        }
        return null;
    }

    public void Set(string key, string value, int ttl = 300)
    {
        if (_redis != null)
        {
            try { _redis.GetDatabase().StringSet(key, value, TimeSpan.FromSeconds(ttl)); }
            catch { }
        }
    }

    public void Delete(string key)
    {
        if (_redis != null)
        {
            try { _redis.GetDatabase().KeyDelete(key); }
            catch { }
        }
    }
}
