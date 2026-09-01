using StackExchange.Redis;
using System.Threading.Tasks;

class RedisCache : ICacheAdapter
{
    private readonly ConnectionMultiplexer _connection;
    private readonly IDatabase _db;
    private readonly LocalCache _fallback;

    public RedisCache(string host)
    {
        _connection = ConnectionMultiplexer.Connect(host);
        _db = _connection.GetDatabase();
        _fallback = new LocalCache();
    }

    public async Task<string> GetAsync(string key)
    {
        try
        {
            RedisValue value = await _db.StringGetAsync(key);
            return value.IsNull ? null : value.ToString();
        }
        catch
        {
            return await _fallback.GetAsync(key);
        }
    }

    public async Task SetAsync(string key, string value, int ttlSeconds)
    {
        try
        {
            await _db.StringSetAsync(key, value, TimeSpan.FromSeconds(ttlSeconds));
        }
        catch
        {
            // redis unavailable
        }
    }

    public async Task RemoveAsync(string key)
    {
        try
        {
            await _db.KeyDeleteAsync(key);
        }
        catch
        {
            // redis unavailable
        }
    }

    public async Task<long> IncrementAsync(string key, int ttlSeconds)
    {
        try
        {
            long count = await _db.StringIncrementAsync(key);
            if (count == 1)
                await _db.KeyExpireAsync(key, TimeSpan.FromSeconds(ttlSeconds));
            return count;
        }
        catch
        {
            return await _fallback.IncrementAsync(key, ttlSeconds);
        }
    }

    public async Task ClearAsync()
    {
        try
        {
            await _db.ExecuteAsync("FLUSHDB");
        }
        catch
        {
            // redis unavailable
        }
    }
}