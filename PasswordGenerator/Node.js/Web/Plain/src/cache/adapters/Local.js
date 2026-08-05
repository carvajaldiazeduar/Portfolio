const CacheAdapter = require('../CacheAdapter');

class Local extends CacheAdapter {
  constructor() {
    super();
    this._store = new Map();
  }

  get(key) {
    if (this._store.has(key)) {
      const entry = this._store.get(key);
      if (entry.expiry > Date.now()) return entry.value;
      this._store.delete(key);
    }
    return null;
  }

  set(key, value, ttl = 300) {
    this._store.set(key, { value, expiry: Date.now() + ttl * 1000 });
  }

  del(key) {
    this._store.delete(key);
  }
}

module.exports = Local;
