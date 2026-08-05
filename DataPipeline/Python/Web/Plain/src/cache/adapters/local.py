import time
from cache.cache_adapter import CacheAdapter


class Local(CacheAdapter):
    def __init__(self):
        self._store = {}

    def get(self, key):
        entry = self._store.get(key)
        if entry is None:
            return None
        if entry["exp"] < time.time():
            del self._store[key]
            return None
        return entry["val"]

    def set(self, key, value, ttl=300):
        self._store[key] = {"val": value, "exp": time.time() + ttl}

    def delete(self, key):
        self._store.pop(key, None)