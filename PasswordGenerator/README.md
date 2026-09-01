# PasswordGenerator

Secure, configurable password generator: length, inclusion of uppercase, lowercase, numbers and symbols, with optional storage of generated passwords. Generation is pure logic; storing passwords uses the same **database + cache** pattern as Inboxes.

## Architecture

Two distinct concerns:

1. **Generation** — pure logic (entropy/random) driven by query params: `length`, `uppercase`, `lowercase`, `numbers`, `symbols`. Stateless, no DB involved.
2. **Storage** — the generated passwords can be saved as a history, which is a classic CRUD over a database with cache. The service layer checks the **cache first** and falls back to the DB on cache misses (300 s TTL; writes invalidate the cache).

```
GET  /generate ──► pure generator ──► { password }
POST /passwords ──► PasswordService ──► ORM ──► PostgreSQL / ...
GET  /passwords ──►  cache-first read
```

## Patterns

- ORM per framework (Eloquent, SQLAlchemy, Django ORM, ActiveRecord, EF Core, JPA, Ecto) for persistence.
- Adapter + Factory for cache (`CacheAdapter` + `CacheFactory` via `CACHE_TYPE`).
- Pure functions isolated from the persistence layer.

## Implementations

| Language | Frameworks |
|---|---|
| PHP | Laravel, Symfony |
| Python | Flask, FastAPI, Django |
| C# | AspNetMinimalApi, Blazor |
| Ruby | RubyOnRails |
| Java | SpringBoot (JPA/Hibernate + Hikari) |
| Elixir | Phoenix (Ecto) |

- **C#**: EF Core `PasswordGeneratorDbContext` + `ICacheAdapter`.
- **Ruby**: ActiveRecord + `Rails.cache`.
- **Elixir**: Ecto (`PasswordEntry` schema + migrations) + `CacheAdapter` behaviour.

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

Compose starts PostgreSQL (5432) + Redis (6379); MySQL/SQL Server/MongoDB commented out. All web apps expose host port `5006` (container ports stay framework-native: Flask/Spring Boot `5000`, Django/FastAPI/Laravel/Symfony `8000`, Rails `3000`, Phoenix `4000`, `elixir:1.17-alpine`). Run with `podman compose up`.

## Tests

- PHP: PHPUnit
- Python: pytest
- C#: xUnit
- Ruby: `rails test`
- Java: JUnit 5 / Spring MockMvc (`mvn test`)
- Elixir: ExUnit (`mix test`)

DB integration tests use `DB_DRIVER=sqlite` + `DB_FILE=test.db`.

Run the suites with no host toolchain (Podman only), from the implementation folder:

```bash
# Java
podman run --rm -v "$(pwd):/app" -w /app -e CACHE_TYPE=local maven:3.9-eclipse-temurin-21 mvn test

# Python (FastAPI/Flask/Django)
podman run --rm -v "$(pwd):/app" -w /app python:3.11-slim sh -c "pip install -q -r src/requirements.txt pytest && python -m pytest tests/ -q"

# .NET
podman run --rm -v "$(pwd):/app" -w /app/src mcr.microsoft.com/dotnet/sdk:10.0-alpine dotnet test tests/<Name>.Tests.csproj -c Release

# Elixir (Phoenix)
podman run --rm -v "$(pwd):/app" -w /app/Elixir/Phoenix/src elixir:1.17-alpine sh -c "mix deps.get && mix test"

# PHP (Laravel / Symfony)
podman run --rm -v "$(pwd):/app" -w /app/PHP/Laravel/Symfony/src php:8.2-cli sh -c "composer install --no-interaction && vendor/bin/phpunit"

# Ruby (RubyOnRails)
podman run --rm -v "$(pwd):/app" -w /app/Ruby/RubyOnRails/src -e DB_DRIVER=sqlite ruby:3.3-slim sh -c "bundle install && RAILS_ENV=test rails db:prepare && rails test"
```
