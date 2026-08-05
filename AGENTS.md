# Portfolio — Agent Guide

## General Structure

```
Project/{PHP,Python,CSharp,Node.js,Ruby}/{CLI,Web}/{Framework}/src/
```

7 projects: Calculator, Chronometer, Contacts, Conversor, Inboxes, PasswordGenerator, TasksList.

## Projects with persistence (DB + Cache)

Contacts, Inboxes, PasswordGenerator, TasksList — the rest have no DB.

## Conventions by Language

### PHP (Plain)
- **Indentation**: 4 spaces
- **Entry**: `src/index.php`
- **DB adapter**: `src/Storage/DatabaseAdapter.php` (interface)
- **DB drivers**: `src/Storage/Adapters/{PostgreSQL,MySQL,SQLite,SQLServer,MongoDB}.php`
- **DB factory**: `src/Storage/DatabaseFactory.php`
- **Cache interface**: `src/Cache/CacheAdapter.php`
- **Cache drivers**: `src/Cache/Adapters/{Redis,Local}.php`
- **Cache factory**: `src/Cache/CacheFactory.php`
- **require_once** instead of autoload

### Python (Plain)
- **Indentation**: 4 spaces
- **Entry**: `src/app.py` (Flask)
- **DB adapter**: `src/storage/database_adapter.py` (ABC)
- **DB drivers**: `src/storage/adapters/{postgresql,mysql,sqlite,sqlserver,mongodb}.py`
- **Cache interface**: `src/cache/cache_adapter.py`
- **Cache drivers**: `src/cache/adapters/{redis,local}.py`
- **Cache factory**: `src/cache/cache_factory.py` (create_cache)

### Node.js (Plain)
- **Indentation**: 2 spaces
- **Entry**: `src/server.js` (Express)
- **DB adapter**: `src/storage/DatabaseAdapter.js` (base class)
- **DB drivers**: `src/storage/adapters/{PostgreSQL,MySQL,SQLite,SQLServer,MongoDB}.js`
- **Cache base**: `src/cache/CacheAdapter.js`
- **Cache drivers**: `src/cache/adapters/{Redis,Local}.js`
- **Cache factory**: `src/cache/CacheFactory.js`

### C# (AspNetMinimalApi / Blazor)
- **Version**: `.Net 9`
- **Indentation**: `4 spaces`
- **Entry**: `src/Program.cs`
- **ORM**: Entity Framework Core (DbContext per project, provider selected by `DB_DRIVER` env var)
- **DB setup**: `src/Storage/DatabaseConfig.cs` (connection string + provider switch: Npgsql, Pomelo, Sqlite, SqlServer, MongoDB.EntityFrameworkCore)
- **DbContext**: `src/Storage/{Project}DbContext.cs` with `DbSet<T>` and `OnModelCreating` mapping table/column names
- **Cache interface**: `src/Cache/ICacheAdapter.cs`
- **Cache drivers**: `src/Cache/Adapters/{Redis,Local}.cs`
- **Cache factory**: `src/Cache/CacheFactory.cs` (CacheComposite)
- **Services**: `src/Services/{Project}Service.cs` (uses DbContext directly, no IDatabaseAdapter)
- **Packages**: Microsoft.EntityFrameworkCore, Npgsql.EntityFrameworkCore.PostgreSQL, Pomelo.EntityFrameworkCore.MySql, Microsoft.EntityFrameworkCore.Sqlite, Microsoft.EntityFrameworkCore.SqlServer, MongoDB.EntityFrameworkCore (experimental)

### Ruby (RubyOnRails)
- **Indentation**: 2 spaces
- **Entry**: `src/config.ru` (Rails full MVC, not API-only). Server on port 3000
- **App**: `src/app/controllers/`, `src/app/models/`, `src/app/views/` (ERB)
- **Routes**: `src/config/routes.rb`. **DB config**: `src/config/database.yml` uses `ENV["DATABASE_URL"]` (URL built in `application.rb` via `DatabaseUrl.build`)
- **DB drivers**: `pg`, `mysql2`, `sqlite3`, `sqlserver` — selected by `DB_DRIVER` (default postgresql)
- **Cache**: `Rails.cache` with `:redis_cache_store` and `:memory_store` fallback (`config/initializers/cache.rb`)
- **Migrations**: `src/db/migrate/*.rb`. The container build runs `rails db:prepare` on startup
- Projects without DB (Calculator, Chronometer, Conversor): no `database.yml`, models, or cache initializer

### ORM Frameworks
- Laravel, Symfony, Flask, FastAPI, Django, Express, RubyOnRails — use separate ORM + cache
- C# Web (AspNetMinimalApi / Blazor) — Entity Framework Core
- Do not modify ORM framework structure unless requested

## Databases

5 configurable drivers via env vars:
- `DB_DRIVER` (default: `pgsql`)
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_FILE` (SQLite)

## Cache

2 levels: Redis (preferred) + Local (fallback), same env vars:
- `CACHE_TYPE` (default: `redis`)
- `REDIS_HOST` (default: `localhost:6379`)
- `CACHE_TTL` (default: `300`)

## Podman

Each web framework keeps standard `Dockerfile` + `docker-compose.yml` names for OCI compatibility, and is intended to run with Podman (`podman compose up`). PostgreSQL is active + Redis. MySQL, SQL Server, MongoDB are commented out.

Do not rename `Dockerfile` to `Podmanfile` or `docker-compose.yml` to `podman-compose.yml` unless the user explicitly requests a full file rename migration.

Recommended commands:
- `podman compose up`
- `podman compose up --build`
- `podman compose down`
- `podman compose config`

`CloudLocal/aws/localstack/pipeline` may need special review because LocalStack can depend on a Docker-compatible socket for some AWS simulation workflows.

## CloudLocal

`CloudLocal/` groups local cloud emulators for AWS, GCP and Azure.

- AWS uses LocalStack under `CloudLocal/aws/localstack`.
- GCP uses Google Cloud SDK emulators where available, plus `fake-gcs-server` for Storage-compatible workflows.
- Azure uses Azurite for Storage and the Cosmos DB Emulator for NoSQL workflows.
- Use provider profiles from `CloudLocal/docker-compose.yml`: `aws`, `gcp`, `azure`, `azure-cosmos`, `all`.
- Keep provider-specific setup inside `CloudLocal/{aws,gcp,azure}` and shared helpers inside `CloudLocal/shared`.

## Scope of Changes

- Keep edits scoped to the project, language, framework, or documentation area requested by the user.
- Do not modify unrelated projects just to make the repository globally consistent unless the user asks for a cross-project sweep.
- When applying a pattern across multiple implementations, inspect at least one nearby existing implementation first.
- Do not change table names, column names, cache keys, routes, public ports, or business behavior unless requested.

## Verification Strategy

- Documentation-only changes: run `rg` checks for stale terms or contradictions.
- Container changes: run `podman compose config` in the touched project when possible.
- Code changes: run the relevant test command for the touched language/project.
- Cross-project shared changes: run a broader sample across affected languages/frameworks.
- If a verification command cannot run because dependencies or services are unavailable, report that clearly.

## Tests

| Language | Framework | Command |
|----------|-----------|---------|
| PHP      | PHPUnit   | `vendor/bin/phpunit` |
| Python   | pytest    | `pytest` |
| C#       | xUnit     | `dotnet test` |
| Node.js  | Jest      | `npm test` |

## Editing Rules

1. **Do not change** ORM framework structure (C# Web uses EF Core; others use their respective ORMs)
2. **Do not add** C# namespaces — use classes in the global namespace
3. **Do not use** autoload in PHP — use `require_once` with relative paths
4. **Do not change** table names, column names, or business logic
5. **Follow** the existing pattern (Adapter for PHP/Python/Node/Ruby; DbContext for C# Web)
6. **Indentation**: PHP/Python/C# = 4 spaces; JS/CSS/HTML = 2 spaces
7. **Do not add** comments unless requested
8. **Verify** `Test-Path` before creating directories; use `New-Item -ItemType Directory -Force`
9. **Default DB**: PostgreSQL
10. **Default cache**: Redis with Local fallback
11. **Run Tests**: Run relevant tests for touched projects. Run broader tests only for shared conventions, cross-project changes, or high-risk edits.
12. **Environment examples**: Keep `.env.example` aligned with documented DB/cache variables.
