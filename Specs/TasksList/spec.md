# TasksList — Spec

## Purpose
Task list (CRUD): create, list, update status (pending/completed) and delete tasks.

## Architecture
Classic CRUD over a database with cache. Persistence layer via `DatabaseAdapter` (interface + factory + per-driver adapters) and cache layer via `CacheAdapter` (Redis/Local). The service layer checks the cache first and falls back to the DB on cache misses.

## Implementations
- **PHP**: Cli + Web (Plain `src/`, Laravel, Symfony)
- **Python**: Cli + Web (Plain `app.py`, Flask, FastAPI, Django, Reflex)
- **CSharp**: Cli + Web (AspNetMinimalApi with EF Core + Blazor)
- **Node.js**: Cli + Web (Express, NextJS, React)
- **Ruby**: Cli + Web (RubyOnRails)

## Adapters
- **DB**: `DatabaseAdapter` + `Adapters/{PostgreSQL,MySQL,SQLite,SQLServer,MongoDB}` + `DatabaseFactory`
- **Cache**: `CacheAdapter` + `Adapters/{Redis,Local}` + `CacheFactory` (`CACHE_TYPE`, `REDIS_HOST`, `CACHE_TTL`)
- C# Web uses EF Core (`TasksListDbContext`) instead of `DatabaseAdapter`.
- Ruby uses Rails ORM + `Rails.cache` (`:redis_cache_store` / `:memory_store`).

## Env vars
- `DB_DRIVER` (default `pgsql`), `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_FILE` (SQLite)
- `CACHE_TYPE` (default `redis`), `REDIS_HOST` (default `localhost:6379`), `CACHE_TTL` (default `300`)

## Endpoints
- `GET /` → UI (`wwwroot/index.html`)
- `GET /tasks` → lists tasks (300s cache)
- `POST /tasks` → creates (validates title)
- `GET /tasks/{id}` → one by id
- `PUT /tasks/{id}` → updates (title and/or completed)
- `DELETE /tasks/{id}` → deletes and invalidates cache
- `GET /openapi.json` → OpenAPI 3.0 spec of this API
- `GET /swagger` → Swagger UI (HTML, loads spec from CDN; FastAPI redirects to `/docs`)

## Tests
| Language | Framework | Where |
|---|---|---|
| C# Cli | xUnit | `Cli/tests/` |
| C# Web | xUnit + Mvc.Testing | `Web/AspNetMinimalApi/src/tests/` |
| Python | pytest | `Cli/tests/` and `Web/*/src/tests/` |
| Node | Jest | `Cli/tests/` and `Web/*/src/tests/` |
| Ruby | Rails | `Web/RubyOnRails/src/` |
| PHP | PHPUnit | frameworks; Plain PHP tests not runnable |

DB integration tests use `DB_DRIVER=sqlite` + `DB_FILE=test.db`.

## Containers / Ports
Compose: PostgreSQL active (5432) + Redis (6379); MySQL/SQL Server/MongoDB commented out. API per framework: Plain/Express/Flask `5000`, Laravel/Django/Rails `8000`, NextJS/React `3000`/`5173`.
