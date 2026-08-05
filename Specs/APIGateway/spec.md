# APIGateway — Spec

## Purpose
API Gateway with JWT authentication, per-IP rate limiting and proxying to backend services (users, orders, products). Routes authenticated requests to the target services and applies request limits.

## Architecture
Middleware chain over the Express router:
1. **Auth**: validates `Authorization: Bearer <JWT>` using `JWT_SECRET`.
2. **Rate limit**: controls per-IP requests using cache (Redis, with local fallback), window + counter.
3. **Proxy**: forwards to the configured backend services via `{X}_SERVICE_URL`.

Only a **Node.js** implementation exists. No DB — only cache for rate limiting.

## Implementations
- **Node.js**: Web (Express) — only implementation

## Adapters
- **Cache**: `CacheAdapter` + `Adapters/{Redis,Local}` + `CacheFactory` (for rate limiting)
- **Middleware**: `middleware/{auth,rateLimit,proxy}.js`

## Env vars
- `JWT_SECRET` — secret to sign/verify tokens
- `USERS_SERVICE_URL`, `ORDERS_SERVICE_URL`, `PRODUCTS_SERVICE_URL` — proxy targets
- `CACHE_TYPE` (default `redis`), `REDIS_HOST` (default `localhost:6379`), `CACHE_TTL` (default `300`)

## Endpoints
- `GET /users` → proxies to `USERS_SERVICE_URL` (requires JWT)
- `GET /orders` → proxies to `ORDERS_SERVICE_URL` (requires JWT)
- `GET /products` → proxies to `PRODUCTS_SERVICE_URL` (requires JWT)
- Any route without a token → `401 Unauthorized`
- Request limit exceeded → `429 Too Many Requests`

## Tests
| Language | Framework | Where |
|---|---|---|
| Node.js | Jest | `src/tests/` |

## Containers / Ports
Compose: API on `3000:3000`, Redis on `6379:6379`. No DB service.
