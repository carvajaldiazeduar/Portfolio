const CacheAdapter = require('../CacheAdapter');

class Local extends CacheAdapter {
  constructor() {
    super();
    this._store = new Map();
    this._timers = new Map();
  }

  get(key) {
    const entry = this._store.get(key);
    if (!entry) return null;
    if (entry.expiresAt && Date.now() > entry.expiresAt) {
      this._store.delete(key);
      return null;
    }
    return entry.value;
  }

  set(key, value, ttl = 300) {
    const expiresAt = ttl > 0 ? Date.now() + ttl * 1000 : null;
    this._store.set(key, { value, expiresAt });
    if (ttl > 0) {
      if (this._timers.has(key)) clearTimeout(this._timers.get(key));
      this._timers.set(key, setTimeout(() => this._store.delete(key), ttl * 1000));
    }
  }

  del(key) {
    this._store.delete(key);
    if (this._timers.has(key)) {
      clearTimeout(this._timers.get(key));
      this._timers.delete(key);
    }
  }

  async increment(key, ttl = 60) {
    const entry = this._store.get(key);
    let count = 1;
    if (entry && (!entry.expiresAt || Date.now() <= entry.expiresAt)) {
      count = (entry.value || 0) + 1;
    }
    this.set(key, count, ttl);
    return count;
  }
}

module.exports = Local;