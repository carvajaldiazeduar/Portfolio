import os
import json
import time
import threading

class CacheAdapter:
    def get(self, key: str):
        raise NotImplementedError
    def set(self, key: str, value, ttl: int = 300):
        raise NotImplementedError
    def delete(self, key: str):
        raise NotImplementedError
    def has(self, key: str) -> bool:
        raise NotImplementedError

class LocalCache(CacheAdapter):
    def __init__(self):
        self._store = {}
        self._lock = threading.Lock()
    def get(self, key: str):
        with self._lock:
            entry = self._store.get(key)
            if entry is None:
                return None
            if entry["expires"] is not None and time.time() > entry["expires"]:
                del self._store[key]
                return None
            return entry["value"]
    def set(self, key: str, value, ttl: int = 300):
        expires = time.time() + ttl if ttl else None
        with self._lock:
            self._store[key] = {"value": value, "expires": expires}
    def delete(self, key: str):
        with self._lock:
            self._store.pop(key, None)
    def has(self, key: str) -> bool:
        return self.get(key) is not None

class RedisCache(CacheAdapter):
    def __init__(self, url="redis://localhost:6379/0"):
        import redis as _redis
        self._client = _redis.from_url(url, decode_responses=True)
    def get(self, key: str):
        val = self._client.get(key)
        if val is None:
            return None
        return json.loads(val)
    def set(self, key: str, value, ttl: int = 300):
        self._client.setex(key, ttl, json.dumps(value))
    def delete(self, key: str):
        self._client.delete(key)
    def has(self, key: str) -> bool:
        return self._client.exists(key) > 0

def create_cache() -> CacheAdapter:
    cache_type = os.getenv("CACHE_TYPE", "redis").lower()
    if cache_type == "local":
        return LocalCache()
    try:
        url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
        return RedisCache(url)
    except Exception:
        return LocalCache()
