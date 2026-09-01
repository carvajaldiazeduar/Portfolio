import threading
import time


class CacheAdapter:
    def get(self, key):
        raise NotImplementedError

    def set(self, key, value, ttl_seconds=300):
        raise NotImplementedError

    def delete(self, key):
        raise NotImplementedError

    def increment(self, key, ttl_seconds):
        raise NotImplementedError

    def clear(self):
        raise NotImplementedError


class LocalCache(CacheAdapter):
    def __init__(self):
        self._store = {}
        self._lock = threading.Lock()

    def get(self, key):
        with self._lock:
            entry = self._store.get(key)
            if entry is None:
                return None
            if entry["expires"] <= time.time():
                del self._store[key]
                return None
            return entry["value"]

    def set(self, key, value, ttl_seconds=300):
        expires = time.time() + ttl_seconds if ttl_seconds > 0 else float("inf")
        with self._lock:
            self._store[key] = {"value": str(value), "expires": expires}

    def delete(self, key):
        with self._lock:
            self._store.pop(key, None)

    def increment(self, key, ttl_seconds):
        with self._lock:
            entry = self._store.get(key)
            if entry is None or entry["expires"] <= time.time():
                value = 1
                expires = time.time() + ttl_seconds if ttl_seconds > 0 else float("inf")
                self._store[key] = {"value": str(value), "expires": expires}
                return value
            value = int(entry["value"]) + 1
            entry["value"] = str(value)
            return value

    def clear(self):
        with self._lock:
            self._store.clear()


class RedisCache(CacheAdapter):
    def __init__(self, host="localhost", port=6379):
        import redis as _redis

        self._client = _redis.Redis(host=host, port=port, decode_responses=True)
        self._client.ping()
        self._fallback = LocalCache()

    def get(self, key):
        try:
            return self._client.get(key)
        except Exception:
            return self._fallback.get(key)

    def set(self, key, value, ttl_seconds=300):
        try:
            self._client.setex(key, ttl_seconds, str(value))
        except Exception:
            pass

    def delete(self, key):
        try:
            self._client.delete(key)
        except Exception:
            pass

    def increment(self, key, ttl_seconds):
        try:
            value = self._client.incr(key)
            self._client.expire(key, ttl_seconds)
            return value
        except Exception:
            return self._fallback.increment(key, ttl_seconds)

    def clear(self):
        try:
            self._client.flushdb()
        except Exception:
            pass


def create_cache():
    import config

    if config.CACHE_TYPE == "local":
        return LocalCache()
    try:
        return RedisCache(host=config.REDIS_HOST, port=config.REDIS_PORT)
    except Exception:
        return LocalCache()