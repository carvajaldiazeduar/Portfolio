using StackExchange.Redis;
using System.Collections.Generic;
using System.Linq;

class RedisCache : ICacheAdapter
{
    private readonly ConnectionMultiplexer _connection;
    private readonly IDatabase _db;

    public RedisCache(string host)
    {
        _connection = ConnectionMultiplexer.Connect(host);
        _db = _connection.GetDatabase();
    }

    public async Task<string> GetAsync(string key)
    {
        RedisValue value = _db.StringGet(key);
        await Task.CompletedTask;
        return value.IsNull ? null : value.ToString();
    }

    public async Task SetAsync(string key, string value, int ttlSeconds)
    {
        _db.StringSet(key, value, TimeSpan.FromSeconds(ttlSeconds));
        await Task.CompletedTask;
    }

    public async Task RemoveAsync(string key)
    {
        _db.KeyDelete(key);
        await Task.CompletedTask;
    }

    public async Task RemoveByPrefixAsync(string prefix)
    {
        foreach (RedisKey key in _connection.GetServer(_connection.GetEndPoints().First()).Keys(pattern: prefix + "*"))
        {
            _db.KeyDelete(key);
        }
        await Task.CompletedTask;
    }

    public async Task<long> IncrementAsync(string key, int ttlSeconds)
    {
        RedisValue count = _db.StringIncrement(key);
        if (count == 1)
        {
            _db.KeyExpire(key, TimeSpan.FromSeconds(ttlSeconds));
        }
        await Task.CompletedTask;
        return (long)count;
    }
}
