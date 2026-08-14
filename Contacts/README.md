# Contacts

Contacts address book (CRUD): create, list, read, update and delete contacts with name, phone and email. This is the reference **database + cache** project — the pattern here is replicated across every persistence-backed project in the portfolio.

## Architecture

Classic CRUD over a database with a two-level cache:

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐     ┌─────────────┐
│  Controller  │ ──► │ ContactService │ ──► │ DatabaseAdapter │ ──► │ PostgreSQL  │
└─────────────┘     └──────────────┘     └────────────────┘     └─────────────┘
        │                   │                      ▲
        │                   └─► CacheAdapter ───────┘
        │                       (Redis / Local)
        ▼
      UI (wwwroot/index.html)
```

The service layer checks the **cache first** and falls back to the DB on cache misses. Read queries are cached with a 300 s TTL; write operations (POST/PUT/DELETE) invalidate the cache automatically.

## Patterns

- **Adapter** for persistence: `DatabaseAdapter` (interface/ABC/base class) + one implementation per driver, selected at runtime.
- **Factory** for driver selection: `DatabaseFactory` based on `DB_DRIVER`.
- **Adapter + Factory** for cache: `CacheAdapter` + `CacheFactory` based on `CACHE_TYPE` (`redis` default, `local` fallback).
- Same domain behavior across languages; full frameworks swap the adapter for their ORM.

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

### How persistence maps per language

- **Plain variants (PHP/Python/Node.js)**: `DatabaseAdapter` + `DatabaseFactory` + `Adapters/{PostgreSQL,MySQL,SQLite,SQLServer,MongoDB}`; cache as `CacheAdapter` + `Adapters/{Redis,Local}`.
- **C# Web**: EF Core `ContactsDbContext` (DbSet + OnModelCreating) + `DatabaseConfig` provider switch + `ICacheAdapter`.
- **Ruby**: Rails ActiveRecord + `Rails.cache` (`:redis_cache_store` / `:memory_store`).
- **Java Web**: Spring Boot JPA/Hibernate + Hikari (`DataSourceConfig`) + `CacheConfig` (`LocalCache`/`RedisCache`); Java Cli uses plain JDBC adapters.
- **Elixir Web**: Ecto (`Contact` schema + `priv/repo/migrations/`) + `CacheAdapter` behaviour (`RedisCache` via Redix / `LocalCache` as a supervised Agent).

## Data model

| Field | Type | Validation |
|---|---|---|
| `name` | string | Required, 2–100 chars, letters/spaces/apostrophes/hyphens/dots |
| `phone` | string | Required, 7–20 chars, digits/spaces/`+`/`(`/`)`/`-` |
| `email` | string | Required, valid email format (`name@domain.tld`) |

Invalid input → **HTTP 400** with `{ "errors": { "<field>": "<message>" } }`. Required-field errors use `<Field> is required`; format errors use a per-field message. Empty/whitespace-only values count as missing.

## Endpoints (Web)

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Contacts UI |
| `GET` | `/contacts` | Lists all contacts (300 s cache) |
| `POST` | `/contacts` | Creates a contact (validates name/phone/email) |
| `GET` | `/contacts/{id}` | One contact by id |
| `PUT` | `/contacts/{id}` | Updates a contact |
| `DELETE` | `/contacts/{id}` | Deletes and invalidates cache |
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

Compose starts PostgreSQL (5432) + Redis (6379); MySQL/SQL Server/MongoDB are commented out. API per framework: Plain/Express/Flask/Spring Boot `5000`, Laravel/Django/Rails `8000`, NextJS/React `3000`/`5173`, Phoenix `4000` (`elixir:1.17-alpine`). Run with `podman compose up`.

## Tests

- Plain PHP: assert (`php -d zend.assertions=1 -d assert.exception=1 tests/*Test.php`, Web with `php -S 127.0.0.1:8000`); frameworks: PHPUnit
- Python: pytest (`Cli/tests/`, `Web/*/src/tests/`)
- C#: xUnit (`Cli/tests/`, `Web/AspNetMinimalApi/src/tests/`)
- Node.js: Jest (`Cli/tests/`, `Web/*/src/tests/`)
- Ruby: `rails test`
- Java: JUnit 5 / Spring MockMvc (`mvn test`)
- Elixir: ExUnit (`mix test` from `Cli/` or `Web/Phoenix/src/`)

DB integration tests use `DB_DRIVER=sqlite` + `DB_FILE=test.db`.

Full contract: [`Specs/Contacts/spec.md`](../Specs/Contacts/spec.md)
