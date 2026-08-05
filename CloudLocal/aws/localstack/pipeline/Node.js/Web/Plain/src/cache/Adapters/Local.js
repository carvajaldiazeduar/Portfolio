class LocalCache {
  constructor() {
    this._store = new Map();
    this._ttls = new Map();
  }

  get(key) {
    if (this._isExpired(key)) {
      this.del(key);
      return null;
    }
    return this._store.get(key) || null;
  }

  set(key, value, ttl = 300) {
    this._store.set(key, value);
    this._ttls.set(key, Date.now() + ttl * 1000);
  }

  del(key) {
    this._store.delete(key);
    this._ttls.delete(key);
  }

  async increment(key, ttl = 60) {
    const current = this.get(key) || 0;
    const newValue = current + 1;
    this.set(key, newValue, ttl);
    return newValue;
  }

  _isExpired(key) {
    const ttl = this._ttls.get(key);
    if (!ttl) return false;
    return Date.now() > ttl;
  }
}

module.exports = { LocalCache };
