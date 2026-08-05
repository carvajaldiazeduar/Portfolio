public static class CacheFactory
{
    public static ICacheAdapter Create()
    {
        var redis = new Redis();
        var local = new Local();
        return new CacheComposite(redis, local);
    }

    private class CacheComposite : ICacheAdapter
    {
        private readonly ICacheAdapter _redis;
        private readonly ICacheAdapter _local;

        public CacheComposite(ICacheAdapter redis, ICacheAdapter local)
        {
            _redis = redis;
            _local = local;
        }

        public string? Get(string key) => _local.Get(key);

        public void Set(string key, string value, int ttl = 300)
        {
            _local.Set(key, value, ttl);
            _redis.Set(key, value, ttl);
        }

        public void Delete(string key)
        {
            _local.Delete(key);
            _redis.Delete(key);
        }
    }
}
