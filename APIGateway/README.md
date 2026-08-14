# APIGateway

API Gateway with **JWT authentication**, **per-IP rate limiting** and **proxying** to backend services (users, orders, products). Routes authenticated requests to the target services and applies request limits. **No DB** — only cache for rate limiting.

## Architecture

Middleware chain over the router. Each concern is isolated in its own middleware/filter and they compose in order:

```
Request ──► Auth (JWT) ──► Rate limit (cache) ──► Proxy (to target service) ──► Response
               │                  │                        │
          401 Unauthorized    429 Too Many            {X}_SERVICE_URL
```

1. **Auth** — validates `Authorization: Bearer <JWT>` using `JWT_SECRET`. Missing/invalid token → `401 Unauthorized`.
2. **Rate limit** — controls per-IP requests using the cache (Redis, with local fallback), window + counter. Over the limit → `429 Too Many Requests`.
3. **Proxy** — forwards to the configured backend services via `USERS_SERVICE_URL` / `ORDERS_SERVICE_URL` / `PRODUCTS_SERVICE_URL`.

## Patterns

- **Middleware chain** for cross-cutting concerns (Node.js `middleware/{auth,rateLimit,proxy}.js`; Java `AuthFilter` + `RateLimitFilter` + `ProxyController`/`ProxyService` with RestTemplate).
- **Adapter + Factory** for cache (`CacheAdapter` + `CacheFactory` via `CACHE_TYPE`), used only for rate limiting.
- JWT is **stateless** — no session store.

## Implementations

| Language | Web |
|---|---|
| Node.js | `Web/Plain` (Express) |
| Java | `Web/SpringBoot` |

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/users` | Proxies to `USERS_SERVICE_URL` (requires JWT) |
| `GET` | `/orders` | Proxies to `ORDERS_SERVICE_URL` (requires JWT) |
| `GET` | `/products` | Proxies to `PRODUCTS_SERVICE_URL` (requires JWT) |
| — | any route without a token | `401 Unauthorized` |
| — | request limit exceeded | `429 Too Many Requests` |
| `GET` | `/openapi.json` | OpenAPI 3.0 spec |
| `GET` | `/swagger` | Swagger UI |

## Env vars

```
JWT_SECRET                        # secret to sign/verify tokens
USERS_SERVICE_URL                 # proxy targets
ORDERS_SERVICE_URL
PRODUCTS_SERVICE_URL
CACHE_TYPE=redis                  # redis (default) | local
REDIS_HOST=localhost:6379
CACHE_TTL=300
```

## Containers / Ports

Compose: API on `3000:3000` (Node) / `5000:5000` (Java), Redis on `6379:6379`. **No DB service.** Run with `podman compose up`.

## Tests

- Node.js: Jest (`src/tests/`)
- Java: JUnit + Spring MockMvc (`mvn test`)

Full contract: [`Specs/APIGateway/spec.md`](../Specs/APIGateway/spec.md)
