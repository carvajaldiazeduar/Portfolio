# Inboxes

Message inbox (CRUD): list messages, read one, create and delete. Each message has a subject, sender, body and a read/unread state. This project follows the same **database + cache** pattern as Contacts/TasksList/PasswordGenerator.

## Architecture

Classic CRUD over a database with a two-level cache. The service layer checks the **cache first** and falls back to the DB on cache misses. Read queries are cached with a 300 s TTL; writes (POST/DELETE) invalidate the cache automatically. Reading a message (`GET /inboxes/{id}`) also marks it as **read**.

```
Controller ──► MessageService ──► DatabaseAdapter ──► PostgreSQL / MySQL / ...
                 │
                 └─► CacheAdapter (Redis / Local)
```

## Patterns

- **Adapter + Factory** for DB (`DatabaseAdapter` + `DatabaseFactory` via `DB_DRIVER`).
- **Adapter + Factory** for cache (`CacheAdapter` + `CacheFactory` via `CACHE_TYPE`).
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

- **Plain variants**: `DatabaseAdapter` + `Adapters/{PostgreSQL,MySQL,SQLite,SQLServer,MongoDB}`.
- **C# Web**: EF Core `InboxesDbContext` + `ICacheAdapter`.
- **Ruby**: ActiveRecord + `Rails.cache`.
- **Elixir Web**: Ecto (`Message` schema + migrations) + `CacheAdapter` behaviour (`RedisCache`/`LocalCache` Agent).

## Data model

| Field | Type | Notes |
|---|---|---|
| `subject` | string | Required on create |
| `from` | string | Sender, required on create |
| `body` | string | Required on create |
| `read` | bool | Unread by default; set to `true` when a message is read |

## Endpoints (Web)

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Inbox UI |
| `GET` | `/inboxes` | Lists messages (300 s cache) |
| `POST` | `/inboxes` | Creates a message (validates subject/from/body) |
| `GET` | `/inboxes/{id}` | One message by id (marks as read) |
| `DELETE` | `/inboxes/{id}` | Deletes and invalidates cache |
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

Full contract: [`Specs/Inboxes/spec.md`](../Specs/Inboxes/spec.md)
