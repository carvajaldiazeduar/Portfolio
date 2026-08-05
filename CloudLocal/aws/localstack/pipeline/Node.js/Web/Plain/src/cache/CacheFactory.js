const RedisCache = require('./adapters/Redis');
const LocalCache = require('./adapters/Local');

function createCache() {
  const local = new LocalCache();
  const redis = new RedisCache();
  return {
    get(key) {
      return local.get(key);
    },
    set(key, value, ttl = 300) {
      local.set(key, value, ttl);
      redis.set(key, value, ttl);
    },
    del(key) {
      local.del(key);
      redis.del(key);
    },
    async increment(key, ttl = 60) {
      const localVal = await local.increment(key, ttl);
      const redisVal = await redis.increment(key, ttl);
      return redisVal !== null ? redisVal : localVal;
    },
  };
}

module.exports = { createCache };
