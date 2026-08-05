class Local {
  constructor() {
    this._store = new Map();
  }

  get(key) {
    const entry = this._store.get(key);
    if (!entry) return null;
    if (entry.exp < Date.now()) {
      this._store.delete(key);
      return null;
    }
    return entry.val;
  }

  set(key, value, ttl = 300) {
    this._store.set(key, { val: value, exp: Date.now() + ttl * 1000 });
  }

  del(key) {
    this._store.delete(key);
  }
}

module.exports = Local;