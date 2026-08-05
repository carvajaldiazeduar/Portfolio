from cache.adapters.redis import Redis
from cache.adapters.local import Local

def create_cache():
    try:
        return Redis()
    except Exception:
        return Local()
