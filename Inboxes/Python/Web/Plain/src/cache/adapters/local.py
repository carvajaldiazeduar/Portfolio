import time
import threading
from cache.cache_adapter import Cache

class Local(Cache):
    def __init__(self):
        self._cache = {}
        self._lock = threading.Lock()

    def get(self, key):
        with self._lock:
            entry = self._cache.get(key)
            if entry and (entry["exp"] is None or entry["exp"] > time.time()):
                return entry["val"]
            if entry:
                del self._cache[key]
        return None

    def set(self, key, value, ttl=300):
        with self._lock:
            self._cache[key] = {"val": value, "exp": time.time() + ttl}

    def delete(self, key):
        with self._lock:
            self._cache.pop(key, None)
