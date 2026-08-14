# PasswordGenerator

Secure, configurable password generator: length, inclusion of uppercase, lowercase, numbers and symbols, with optional storage of generated passwords. Generation is pure logic; storing passwords uses the same **database + cache** pattern as Contacts/TasksList/Inboxes.

## Architecture

Two distinct concerns:

1. **Generation** — pure logic (entropy/random) driven by query params: `length`, `uppercase`, `lowercase`, `numbers`, `symbols`. Stateless, no DB involved.
2. **Storage** — the generated passwords can be saved as a history, which is a classic CRUD over a database with cache. The service layer checks the **cache first** and falls back to the DB on cache misses (300 s TTL; writes invalidate the cache).

```
GET  /generate ──► pure generator ──► { password }
POST /passwords ──► PasswordService ──► DatabaseAdapter ──► PostgreSQL / ...
GET  /passwords ──►  cache-first read
```

## Patterns

- **Adapter + Factory** for DB (`DatabaseAdapter` + `DatabaseFactory` via `DB_DRIVER`).
- **Adapter + Factory** for cache (`CacheAdapter` + `CacheFactory` via `CACHE_TYPE`).
- Pure functions isolated from the persistence layer.

## Implementations

| Language | Cli | Web |
|---|---|---|
| PHP | `Cli` | `Web/{Plain,Laravel,Symfony}` |
| Python | `Cli` | `Web/{Plain,Flask,FastAPI,Django,Reflex}` |
| C# | `Cli` | `Web/{AspNetMinimalApi,Blazor}` |
| Node.js | `Cli` | `Web/{Plain,Express,NextJS,React}` |
| Ruby | `Cli` | `Web/RubyOnRails` |
| Java | `Cli` (plain JDBC) | `Web/SpringBoot` (JPA/Hibernate + Hikari) |
| Elixir | `Cli` (mix escript) | `Web/Phoenix` (Ecto) |

- **Plain variants**: `DatabaseAdapter` + `Adapters/{PostgreSQL,MySQL,SQLite,SQLServer,MongoDB}`.
- **C# Web**: EF Core `PasswordGeneratorDbContext` + `ICacheAdapter`.
- **Ruby**: ActiveRecord + `Rails.cache`.
- **Elixir Web**: Ecto (`PasswordEntry` schema + migrations) + `CacheAdapter` behaviour.

## Data model

| Field | Type | Notes |
|---|---|---|
| `password` | string | Stored password |
| `length` | int | Length used to generate it |

## Endpoints (Web)

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Password generator UI |
| `GET` | `/generate` | `length`, `uppercase`, `lowercase`, `numbers`, `symbols` → `{ "password": string }` |
| `POST` | `/passwords` | Stores a generated password |
| `GET` | `/passwords` | Lists stored passwords (300 s cache) |
| `DELETE` | `/passwords/{id}` | Deletes and invalidates cache |
| `GET` | `/openapi.json` | OpenAPI 3.0 spec |
| `GET` | `/swagger` | Swagger UI |

## Env vars

```
DB_DRIVER=pgsql            # pgsql | mysql | sqlite | sqlserver | mongodb (default pgsql)
DB_HOST / DB_PORT / DB_NAME / DB_USER / DB_PASSWORD / DB_FILE (SQLite)
CACHE_TYPE=redis           # redis (default) | local
REDIS_HOST=localhost:6379
CACHE_TTL=300
```

## Containers / Ports

Compose starts PostgreSQL (5432) + Redis (6379); MySQL/SQL Server/MongoDB commented out. API per framework: Plain/Express/Flask/Spring Boot `5000`, Laravel/Django/Rails `8000`, NextJS/React `3000`/`5173`, Phoenix `4000` (`elixir:1.17-alpine`). Run with `podman compose up`.

## Tests

- Plain PHP: assert; frameworks: PHPUnit
- Python: pytest
- C#: xUnit
- Node.js: Jest
- Ruby: `rails test`
- Java: JUnit 5 / Spring MockMvc (`mvn test`)
- Elixir: ExUnit (`mix test`)

DB integration tests use `DB_DRIVER=sqlite` + `DB_FILE=test.db`.

Full contract: [`Specs/PasswordGenerator/spec.md`](../Specs/PasswordGenerator/spec.md)
