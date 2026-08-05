const Redis = require('ioredis');
const CacheAdapter = require('../CacheAdapter');

class RedisCache extends CacheAdapter {
  constructor() {
    super();
    this._client = null;
  }

  _getClient() {
    if (!this._client) {
      this._client = new Redis({
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379'),
        maxRetriesPerRequest: null,
      });
    }
    return this._client;
  }

  async get(key) {
    const client = this._getClient();
    const value = await client.get(key);
    return value ? JSON.parse(value) : null;
  }

  async set(key, value, ttl = 300) {
    const client = this._getClient();
    await client.set(key, JSON.stringify(value), 'EX', ttl);
  }

  async del(key) {
    const client = this._getClient();
    await client.del(key);
  }

  async increment(key, ttl = 60) {
    const client = this._getClient();
    const value = await client.incr(key);
    if (value === 1) {
      await client.expire(key, ttl);
    }
    return value;
  }
}

module.exports = { RedisCache };
