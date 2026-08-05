const CacheAdapter = require('../CacheAdapter');

class Redis extends CacheAdapter {
  constructor() {
    super();
    this._client = null;
    try {
      const Redis = require('ioredis');
      this._client = new Redis(process.env.REDIS_HOST || 'localhost:6379', { lazyConnect: true, maxRetriesPerRequest: 0 });
      this._client.connect().catch(() => { this._client = null; });
    } catch { this._client = null; }
  }

  async get(key) {
    if (!this._client) return null;
    try {
      const val = await this._client.get(key);
      return val ? JSON.parse(val) : null;
    } catch { return null; }
  }

  async set(key, value, ttl = 300) {
    if (!this._client) return;
    try { await this._client.setex(key, ttl, JSON.stringify(value)); } catch {}
  }

  async del(key) {
    if (!this._client) return;
    try { await this._client.del(key); } catch {}
  }
}

module.exports = Redis;
