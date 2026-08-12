# Contacts — Spec

## Purpose
Contacts address book (CRUD): create, list, read, update and delete contacts with name, phone and email.

## Architecture
Classic CRUD over a database with cache. Persistence layer via `DatabaseAdapter` (interface + factory + per-driver adapters) and cache layer via `CacheAdapter` (Redis/Local). The service layer checks the cache first and falls back to the DB on cache misses.

## Implementations
- **PHP**: Cli + Web (Plain `src/`, Laravel, Symfony)
- **Python**: Cli + Web (Plain `app.py`, Flask, FastAPI, Django, Reflex)
- **CSharp**: Cli + Web (AspNetMinimalApi with EF Core + Blazor)
- **Node.js**: Cli + Web (Express, NextJS, React)
- **Ruby**: Cli + Web (RubyOnRails)
- **Java**: Cli + Web (Spring Boot 3.3.4, Java 21; EF Core equivalent via plain JDBC adapters in Cli)

## Adapters
- **DB**: `DatabaseAdapter` + `Adapters/{PostgreSQL,MySQL,SQLite,SQLServer,MongoDB}` + `DatabaseFactory`
- **Cache**: `CacheAdapter` + `Adapters/{Redis,Local}` + `CacheFactory` (`CACHE_TYPE`, `REDIS_HOST`, `CACHE_TTL`)
- C# Web uses EF Core (`ContactsDbContext`) instead of `DatabaseAdapter`.
- Ruby uses Rails ORM + `Rails.cache` (`:redis_cache_store` / `:memory_store`).
- Java Web uses Spring Boot JPA/Hibernate + Hikari (`DataSourceConfig`) + `CacheConfig` with `LocalCache`/`RedisCache` instead of `DatabaseAdapter`; Java Cli uses plain JDBC adapters.

## Env vars
- `DB_DRIVER` (default `pgsql`), `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_FILE` (SQLite)
- `CACHE_TYPE` (default `redis`), `REDIS_HOST` (default `localhost:6379`), `CACHE_TTL` (default `300`)

## Endpoints
- `GET /` → UI (`wwwroot/index.html`)
- `GET /contacts` → lists all (300s cache)
- `POST /contacts` → creates (validates name/phone/email)
- `GET /contacts/{id}` → one by id
- `PUT /contacts/{id}` → updates
- `DELETE /contacts/{id}` → deletes and invalidates cache
- `GET /openapi.json` → OpenAPI 3.0 spec of this API
- `GET /swagger` → Swagger UI (HTML, loads spec from CDN; FastAPI redirects to `/docs`)

## Validation

Fields are validated on create/update. Invalid input returns **HTTP 400** with
`{ "errors": { "<field>": "<message>" } }` (only invalid fields present). The CLI
prints the error and does nothing. The web UI marks each invalid field with a red
border + inline message and valid fields with a green border.

| Field | Rule |
|---|---|
| `name` | Required. 2–100 characters. Allowed: letters, spaces, apostrophes, hyphens, dots. |
| `phone` | Required. 7–20 characters. Allowed: digits, spaces, `+`, `(`, `)`, `-`. |
| `email` | Required. Must match a valid email format (`name@domain.tld`). |

Required-field errors use `<Field> is required`; format errors use a descriptive
per-field message. Empty/whitespace-only values are treated as missing.

## Tests
| Language | Framework | Where |
|---|---|---|
| C# Cli | xUnit | `Cli/tests/` |
| C# Web | xUnit + Mvc.Testing | `Web/AspNetMinimalApi/src/tests/` |
| Python | pytest | `Cli/tests/` and `Web/*/src/tests/` |
| Node | Jest | `Cli/tests/` and `Web/*/src/tests/` |
| Ruby | Rails | `Web/RubyOnRails/src/` |
| PHP | assert | Cli via `php -d zend.assertions=1 -d assert.exception=1 tests/*Test.php`; frameworks via PHPUnit; Plain Web via assert + `php -S 127.0.0.1:8000 index.php` |
| Java Cli | JUnit 5 (Maven) | `Java/Cli` via `mvn test` |
| Java Web | JUnit + Spring MockMvc (Maven) | `Java/Web/SpringBoot` via `mvn test` |

DB integration tests use `DB_DRIVER=sqlite` + `DB_FILE=test.db`.

## Containers / Ports
Compose: PostgreSQL active (5432) + Redis (6379); MySQL/SQL Server/MongoDB commented out. API per framework: Plain/Express/Flask/Spring Boot `5000`, Laravel/Django/Rails `8000`, NextJS/React `3000`/`5173`.
