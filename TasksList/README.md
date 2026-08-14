# TasksList

Task list (CRUD): create, list, update status (pending/completed) and delete tasks. This project follows the same **database + cache** pattern as Contacts/Inboxes/PasswordGenerator.

## Architecture

Classic CRUD over a database with a two-level cache. The service layer checks the **cache first** and falls back to the DB on cache misses. Read queries are cached with a 300 s TTL; writes (POST/PUT/DELETE) invalidate the cache automatically.

```
Controller ──► TaskService ──► DatabaseAdapter ──► PostgreSQL / MySQL / ...
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
- **C# Web**: EF Core `TasksListDbContext` + `ICacheAdapter`.
- **Ruby**: ActiveRecord + `Rails.cache`.
- **Elixir Web**: Ecto (`Task` schema + migrations) + `CacheAdapter` behaviour.

## Data model

| Field | Type | Notes |
|---|---|---|
| `title` | string | Required, validated on create |
| `description` | string | Optional |
| `completed` | bool | `pending`/`completed` status |

## Endpoints (Web)

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Tasks UI |
| `GET` | `/tasks` | Lists tasks (300 s cache) |
| `POST` | `/tasks` | Creates a task (validates title) |
| `GET` | `/tasks/{id}` | One task by id |
| `PUT` | `/tasks/{id}` | Updates title and/or completed |
| `DELETE` | `/tasks/{id}` | Deletes and invalidates cache |
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

Full contract: [`Specs/TasksList/spec.md`](../Specs/TasksList/spec.md)
