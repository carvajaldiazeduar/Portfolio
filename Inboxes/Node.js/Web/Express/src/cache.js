const os = require('os');

class CacheAdapter {
    get(key) { throw new Error('Not implemented'); }
    set(key, value, ttl) { throw new Error('Not implemented'); }
    delete(key) { throw new Error('Not implemented'); }
    has(key) { throw new Error('Not implemented'); }
}

class LocalCache extends CacheAdapter {
    constructor() {
        super();
        this._store = new Map();
    }
    get(key) {
        const entry = this._store.get(key);
        if (!entry) return null;
        if (entry.expires && Date.now() > entry.expires) {
            this._store.delete(key);
            return null;
        }
        return entry.value;
    }
    set(key, value, ttl = 300) {
        this._store.set(key, { value, expires: ttl ? Date.now() + ttl * 1000 : null });
    }
    delete(key) { this._store.delete(key); }
    has(key) { return this.get(key) !== null; }
}

class RedisCache extends CacheAdapter {
    constructor(url) {
        super();
        const Redis = require('ioredis');
        this._client = new Redis(url || 'redis://localhost:6379');
    }
    async get(key) {
        const val = await this._client.get(key);
        if (!val) return null;
        return JSON.parse(val);
    }
    async set(key, value, ttl = 300) {
        await this._client.setex(key, ttl, JSON.stringify(value));
    }
    async delete(key) { await this._client.del(key); }
    async has(key) { return (await this._client.exists(key)) > 0; }
}

function createCache() {
    const type = process.env.CACHE_TYPE || 'redis';
    if (type === 'local') return new LocalCache();
    try {
        const url = process.env.REDIS_URL || 'redis://localhost:6379';
        return new RedisCache(url);
    } catch (e) {
        return new LocalCache();
    }
}

module.exports = { createCache, LocalCache, RedisCache };
