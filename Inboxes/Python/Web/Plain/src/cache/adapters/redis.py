import os
import json
from cache.cache_adapter import Cache

class Redis(Cache):
    def __init__(self):
        import redis as r
        host, port = os.getenv("REDIS_HOST", "localhost:6379").split(":")
        self._redis = r.Redis(host=host, port=int(port), socket_connect_timeout=1)
        self._redis.ping()

    def get(self, key):
        val = self._redis.get(key)
        return json.loads(val) if val else None

    def set(self, key, value, ttl=300):
        self._redis.setex(key, ttl, json.dumps(value))

    def delete(self, key):
        self._redis.delete(key)
