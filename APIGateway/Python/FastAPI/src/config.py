import os

JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret-change-in-production")

CACHE_TYPE = os.getenv("CACHE_TYPE", "redis").lower()
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))

RATE_LIMIT_DEFAULT = int(os.getenv("RATE_LIMIT_DEFAULT", "100"))
RATE_LIMIT_WINDOW = int(os.getenv("RATE_LIMIT_WINDOW", "60"))

# Per-route limits (requests per window seconds)
ROUTE_LIMITS = {
    "/api/users": {"limit": int(os.getenv("USERS_LIMIT", "50")), "window": int(os.getenv("USERS_WINDOW", "60"))},
    "/api/orders": {"limit": int(os.getenv("ORDERS_LIMIT", "30")), "window": int(os.getenv("ORDERS_WINDOW", "60"))},
    "/api/products": {"limit": int(os.getenv("PRODUCTS_LIMIT", "100")), "window": int(os.getenv("PRODUCTS_WINDOW", "60"))},
}

SERVICES = {
    "users": os.getenv("USERS_SERVICE_URL", "http://localhost:3001"),
    "orders": os.getenv("ORDERS_SERVICE_URL", "http://localhost:3002"),
    "products": os.getenv("PRODUCTS_SERVICE_URL", "http://localhost:3003"),
}