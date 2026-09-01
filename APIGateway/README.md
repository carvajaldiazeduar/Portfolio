# APIGateway

API Gateway with **JWT authentication**, **per-IP rate limiting** and **proxying** to backend services (users, orders, products). Routes authenticated requests to the target services and applies request limits. **No DB** — only cache for rate limiting.

## Architecture

Middleware chain over the router. Each concern is isolated in its own middleware/filter and they compose in order:

```
Request ──► Auth (JWT) ──► Rate limit (cache) ──► Proxy (to target service) ──► Response
               │                  │                        │
          401 Unauthorized    429 Too Many            {X}_SERVICE_URL
```

1. **Auth** — validates `Authorization: Bearer <JWT>` (HS256, signed with `JWT_SECRET`). Missing/invalid/expired token → `401 Unauthorized`.
2. **Rate limit** — controls per-IP requests using the cache (Redis, with local fallback), window + counter. Over the limit → `429 Too Many Requests` with `X-RateLimit-*` headers.
3. **Proxy** — forwards to the configured backend services via `USERS_SERVICE_URL` / `ORDERS_SERVICE_URL` / `PRODUCTS_SERVICE_URL`. Upstream down → `502 Bad Gateway`.

## Patterns

- **Middleware chain** for cross-cutting concerns (Java `AuthFilter` + `RateLimitFilter` + `ProxyController`/`ProxyService`; FastAPI/ASP.NET use ordered middleware).
- **Adapter + Factory** for cache (`CacheAdapter`/`CacheFactory` via `CACHE_TYPE`), used only for rate limiting, with Redis + local fallback.
- JWT is **stateless** (HS256) — no session store.
- **Proxy** forwards any subpath under `/api/{service}` to the configured upstream.

## Implementations

| Language | Frameworks | Tests |
|---|---|---|
| Java | SpringBoot | JUnit + Spring MockMvc |
| Python | FastAPI + httpx | pytest |
| .NET 10 | ASP.NET Core Minimal API | xUnit |

## Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/auth/login` | Returns a JWT → `{token, expiresIn: "1h"}` (`admin`/`admin` → id 1, `user`/`user` → id 2) |
| `GET` | `/api/users/*` | Proxies to `USERS_SERVICE_URL` (requires JWT, 50 req/min) |
| `GET` | `/api/orders/*` | Proxies to `ORDERS_SERVICE_URL` (requires JWT, 30 req/min) |
| `GET` | `/api/products/*` | Proxies to `PRODUCTS_SERVICE_URL` (requires JWT, 100 req/min) |
| `GET` | `/health` | Health check → `{status, timestamp}` |
| `GET` | `/swagger` | Redirects to `/swagger.html` |
| `GET` | `/` | Static UI (login + endpoint tester) |
| — | any route without a token | `401 Unauthorized` |
| — | request limit exceeded | `429 Too Many Requests` |

## Env vars

```
JWT_SECRET                        # secret to sign/verify tokens
USERS_SERVICE_URL                 # proxy targets
ORDERS_SERVICE_URL
PRODUCTS_SERVICE_URL
CACHE_TYPE=redis                  # redis (default) | local
REDIS_HOST=redis                  # container/service host
REDIS_PORT=6379
RATE_LIMIT_DEFAULT=100            # default limit per window
RATE_LIMIT_WINDOW=60              # window in seconds
USERS_LIMIT=50                    # per-route limits
ORDERS_LIMIT=30
PRODUCTS_LIMIT=100
```

## Containers / Ports

- **Java** (`Java/SpringBoot`): app on `5006:5000`, Redis on `6379`.
- **Python** (`Python/FastAPI`): app on `5006:5000`, Redis on `6379` (compose offset `6380`).
- **.NET 10** (`DotNet/AspNetMinimalApi`): app on `5006:5000`, Redis on `6380`.

Run each with `podman compose up` from its folder. **No DB service** needed.

## Tests

Run each suite inside a container (no host toolchain required), from the implementation folder:

### Java (`Java/SpringBoot`)

```bash
podman run --rm -v "$(pwd):/app" -w /app -e CACHE_TYPE=local maven:3.9-eclipse-temurin-21 mvn test
```

JUnit + Spring MockMvc: login (200/400/401), auth 401, rate limit 429, proxy 502, `/health`.

### Python (`Python/FastAPI`)

```bash
podman run --rm -v "$(pwd):/app" -w /app python:3.11-slim sh -c "pip install -q -r src/requirements.txt pytest && python -m pytest tests/ -q"
```

pytest: login (200/400/401), public UI/index, `/swagger` redirect, auth 401, valid token pass-through, rate limit 429.

### .NET 10 (`DotNet/AspNetMinimalApi`)

```bash
podman run --rm -v "$(pwd):/app" -w /app/src mcr.microsoft.com/dotnet/sdk:10.0-alpine dotnet test tests/APIGateway.Tests.csproj -c Release
```

xUnit: login token + `expiresIn: "1h"`, JWT HS256 sign/verify/expiry, `LocalCache` get/set/increment/remove/clear/expiry.

### End-to-end

Run the gateway and point the browser at **`http://localhost:5006`**:

```bash
podman compose up --build
```

No upstream services are bundled — they are reached externally via `USERS_SERVICE_URL` / `ORDERS_SERVICE_URL` / `PRODUCTS_SERVICE_URL` (defaults `3001`/`3002`/`3003`), so protected routes answer `502` unless you run those backends. Rate limits: `/api/users` 50/min, `/api/orders` 30/min, `/api/products` 100/min, default 100/min (all overridable via env).
