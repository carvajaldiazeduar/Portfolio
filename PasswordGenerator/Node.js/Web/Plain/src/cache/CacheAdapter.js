class CacheAdapter {
  get(key) { throw new Error('Not implemented'); }
  set(key, value, ttl) { throw new Error('Not implemented'); }
  del(key) { throw new Error('Not implemented'); }
}
module.exports = CacheAdapter;
