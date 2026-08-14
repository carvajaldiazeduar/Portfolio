# Portfolio — Agent Guide

## General Structure

```
Project/{PHP,Python,CSharp,Node.js,Ruby,Java,Elixir}/{Cli,Web}/{Framework}/src/
```

There are **13 top-level items**: 7 core apps (Calculator, Chronometer, Contacts, Conversor, Inboxes, PasswordGenerator, TasksList) + specialized projects (APIGateway, ChatAI, DataPipeline, EventProcessor, SemanticSearch) + `CloudLocal/` (cloud emulator infra, not an app).

## Specs

- `Specs/<Project>/spec.md` holds the spec for each project. Each spec documents purpose, architecture, adapters, env vars, endpoints, and tests.
- Every project (including new ones like `ChatAI`) gets a `Specs/<Project>/spec.md`.
- **When a project's behavior changes, update its spec to stay in sync.**

## Persistence

| Project | Storage pattern |
|---|---|
| Contacts, Inboxes, PasswordGenerator, TasksList | Classic `DatabaseAdapter` (DB) + `CacheAdapter` (DB_DRIVER / CACHE_TYPE) |
| Calculator, Chronometer, Conversor | No persistence |
| APIGateway (Node.js only) | Cache only (rate limiting), no DB |
| EventProcessor (Node.js only) | `QueueAdapter` (QUEUE_DRIVER: redis/rabbitmq/kafka/sqs), no DB |
| DataPipeline (Python only) | `DataWarehouseAdapter` (WAREHOUSE_DRIVER: duckdb/bigquery/postgresql, default duckdb) + cache |
| SemanticSearch | `VectorStoreAdapter` (VECTOR_DRIVER: chromadb/pinecone/pgvector) + cache |

Elixir (Phoenix) uses Ecto for DB-backed projects (Contacts, Inboxes, PasswordGenerator, TasksList) and implements the same `CacheAdapter` behavior (`CacheType` via `CACHE_TYPE`). Stateless projects (Calculator, Chronometer, Conversor) skip Ecto and cache. ChatAI (Elixir) is stateless — no DB/cache.

New specialized projects (DataPipeline, SemanticSearch) are covered in README.md alongside APIGateway, EventProcessor and CloudLocal.

## Adapter conventions by Language

### PHP (Plain)
- **Indentation**: 4 spaces
- **Entry**: `src/index.php`
- **require_once** with relative paths — no autoload, no composer.json
- **DB**: `src/Storage/DatabaseAdapter.php` (interface) + `src/Storage/Adapters/{PostgreSQL,MySQL,SQLite,SQLServer,MongoDB}.php` + `src/Storage/DatabaseFactory.php`
- **Cache**: `src/Cache/CacheAdapter.php` + `src/Cache/Adapters/{Redis,Local}.php` + `src/Cache/CacheFactory.php`
- **EXCEPTION**: `SemanticSearch/PHP/Web/Plain` keeps its cache classes under `src/Storage/` (CacheAdapter.php, CacheFactory.php, Adapters/{Local,Redis}.php) and its vector drivers under `src/Storage/Adapters/{ChromaDB,PgVector,Pinecone}.php`. Don't "fix" it — it's the established layout there.

### Python (Plain)
- **Indentation**: 4 spaces
- **Entry**: `src/app.py` (Flask)
- **DB**: `src/storage/database_adapter.py` (ABC) + `src/storage/adapters/{postgresql,mysql,sqlite,sqlserver,mongodb}.py` + `src/storage/database_factory.py`
- **Cache**: `src/cache/cache_adapter.py` + `src/cache/adapters/{redis,local}.py` + `src/cache/cache_factory.py` (`create_cache`)
- **DataPipeline uses `warehouse_adapter.py` / `warehouse_factory.py` / `adapters/{duckdb,bigquery,postgresql}.py` instead of the database_* names.**

### Node.js (Plain)
- **Indentation**: 2 spaces
- **Entry**: `src/server.js` (Express)
- **DB**: `src/storage/DatabaseAdapter.js` (base class) + `src/storage/adapters/{PostgreSQL,MySQL,SQLite,SQLServer,MongoDB}.js` + `src/storage/DatabaseFactory.js`
- **Cache**: `src/cache/CacheAdapter.js` + `src/cache/adapters/{Redis,Local}.js` + `src/cache/CacheFactory.js`
- **EventProcessor adds `src/queue/` (QueueAdapter.js, QueueFactory.js, adapters/{RedisQueue,RabbitMQ,Kafka,SQS}.js) and a separate `worker.js`.** APIGateway has no DB — only `middleware/` (auth, rateLimit, proxy) + cache.

### C# (AspNetMinimalApi / Blazor)
- **Target framework**: `net9.0` (all csproj files and Dockerfiles; EF Core / ASP.NET packages at 9.x, MongoDB.EntityFrameworkCore at 9.1.x, Npgsql.EntityFrameworkCore.PostgreSQL at 9.0.x)
- **Indentation**: 4 spaces; classes in the global namespace (no namespaces)
- **Entry**: `src/Program.cs`
- **ORM**: Entity Framework Core — `src/Storage/{Project}DbContext.cs` (DbSet<T> + OnModelCreating) + `src/Storage/DatabaseConfig.cs` (connection string + provider switch: Npgsql, Pomelo, Sqlite, SqlServer, MongoDB.EntityFrameworkCore). Services: `src/Services/{Project}Service.cs` use the DbContext directly.
- **Cache**: `src/Cache/ICacheAdapter.cs` + `src/Cache/Adapters/{Redis,Local}.cs` + `src/Cache/CacheFactory.cs` (CacheComposite)
- **EXCEPTION**: `SemanticSearch/CSharp` does NOT use EF Core. It defines `VectorStoreAdapter` / `CacheAdapter` abstract classes inline in `Program.cs` (no Storage/ folder). Don't add a DbContext there.

### Ruby (RubyOnRails)
- **Indentation**: 2 spaces
- **Entry**: `src/config.ru` (full MVC, not API-only). Server on port 3000
- **Routes**: `src/config/routes.rb`. **DB config**: `src/config/database.yml` uses `ENV["DATABASE_URL"]` (URL built in `application.rb` via `DatabaseUrl.build`)
- **DB drivers**: `pg`, `mysql2`, `sqlite3`, `sqlserver` — selected by `DB_DRIVER` (default postgresql)
- **Cache**: `Rails.cache` with `:redis_cache_store` and `:memory_store` fallback (`config/initializers/cache.rb`)
- **Migrations**: `src/db/migrate/*.rb`. The container build runs `rails db:prepare` on startup
- Projects without DB (Calculator, Chronometer, Conversor, SemanticSearch): no `database.yml`, models, or cache initializer

### Elixir (Phoenix)
- **Indentation**: 2 spaces
- **Entry**: `src/lib/<app>/` (Application + Endpoint + Router + Controllers). Server on port 4000
- **Framework**: Phoenix `~> 1.8`, Elixir 1.17. Full MVC — `src/lib/<app>_web/` (controllers/router) + `src/lib/<app>/` (contexts/schemas)
- **ORM**: Ecto `~> 3.13` — `src/lib/<app>/repo.ex` + `src/lib/<app>/<context>/<schema>.ex` + `src/priv/repo/migrations/`. Runtime repo config builds the adapter from `DB_DRIVER` (postgrex/myxql/tds/ecto_sqlite3/mongodb_ecto)
- **Cache**: `src/lib/<app>/cache/` — `CacheAdapter` behaviour + `CacheFactory` (`create_cache/1` returns `RedisCache`/`LocalCache` by `CACHE_TYPE`). LocalCache is an Agent (GenServer) under the app supervisor; RedisCache uses Redix
- **Tests**: ExUnit (`mix test`) run from `src/`; Phoenix controller tests use `Phoenix.ConnTest` (`src/test/<app>_web/controllers/`)
- **Actors (OTP)**: Chronometer Web keeps the stopwatch state in a supervised `GenServer`. ChatAI bounds provider HTTP calls with `Task.async`/`Task.yield(timeout)` for `CHAT_TIMEOUT_MS`
- **Projects without DB** (Calculator, Chronometer, Conversor, ChatAI): no Repo, no migrations, no cache files
- **EXCEPTION**: `SemanticSearch/Elixir` keeps its vector drivers under `src/lib/<app>/vectorstore/` (`VectorStoreAdapter` behaviour + `VectorStoreFactory` + `{ChromaDB,PgVector,Pinecone,InMemory}`) and cache via the same `CacheAdapter`. Don't add a Repo there.

### ORM Frameworks
- Laravel, Symfony, Flask, FastAPI, Django, Express, RubyOnRails, Phoenix (Ecto) — use their own ORM + cache. C# Web uses EF Core. Do not modify ORM framework structure unless requested.

## Databases

5 configurable drivers via env vars:
- `DB_DRIVER` (default: `pgsql`)
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_FILE` (SQLite)

## Cache

2 levels: Redis (preferred) + Local (fallback), same env vars:
- `CACHE_TYPE` (default: `redis`)
- `REDIS_HOST` (default: `localhost:6379`)
- `CACHE_TTL` (default: `300`)

## Extra env vars (specialized projects)

- DataPipeline: `WAREHOUSE_DRIVER` (default `duckdb`)
- SemanticSearch: `VECTOR_DRIVER` (default `chromadb`), `VECTOR_DIMENSION` (1536), `VECTOR_COLLECTION` (documents)
- EventProcessor: `QUEUE_DRIVER` (default `redis`)
- APIGateway: `JWT_SECRET`, `USERS_SERVICE_URL`, `ORDERS_SERVICE_URL`, `PRODUCTS_SERVICE_URL`
- CloudLocal has its own `CloudLocal/.env.example` (AWS/GCP/Azure emulator endpoints)

## Podman

Each web framework keeps standard `Dockerfile` + `docker-compose.yml` names for OCI compatibility, and is intended to run with Podman. PostgreSQL is active + Redis. MySQL, SQL Server, MongoDB are commented out. SemanticSearch composes add a `chroma` service. EventProcessor compose has both `event-processor-api` and `event-processor-worker` services. **C# Dockerfiles use `mcr.microsoft.com/dotnet/{sdk,aspnet}:9.0-alpine`** — keep them alpine when bumping versions.

Do not rename `Dockerfile` to `Podmanfile` or `docker-compose.yml` to `podman-compose.yml` unless the user explicitly requests a full file rename migration.

Recommended commands (run in the project folder):
- `podman compose up`
- `podman compose up --build`
- `podman compose down`
- `podman compose config`

`CloudLocal/aws/localstack/pipeline` may need special review because LocalStack can depend on a Docker-compatible socket for some AWS simulation workflows.

## CloudLocal

- AWS uses LocalStack under `CloudLocal/aws/localstack`. GCP uses Google Cloud SDK emulators + `fake-gcs-server` for Storage. Azure uses Azurite + Cosmos DB Emulator.
- Start per provider with profiles: `podman compose --profile aws up`, `--profile gcp up`, `--profile azure up`, `--profile azure-cosmos up`, `--profile all up` (run from `CloudLocal/`).
- Keep provider-specific setup inside `CloudLocal/{aws,gcp,azure}` and shared helpers inside `CloudLocal/shared`.

## Scope of Changes

- Keep edits scoped to the project, language, framework, or documentation area requested by the user.
- Do not modify unrelated projects just to make the repository globally consistent unless the user asks for a cross-project sweep.
- When applying a pattern across multiple implementations, inspect at least one nearby existing implementation first.
- Do not change table names, column names, cache keys, routes, public ports, or business behavior unless requested.

## Tests

| Language | Framework | Command | Where to run |
|----------|-----------|---------|--------------|
| PHP      | PHPUnit   | `vendor/bin/phpunit` | framework projects (Laravel/Symfony) after `composer install`. Plain PHP **CLI** tests run with `php -d zend.assertions=1 -d assert.exception=1 tests/*Test.php`; plain PHP **Web** tests run the same way against a built-in server (`php -S 127.0.0.1:8000 index.php`) with `DB_DRIVER=sqlite` + `DB_FILE` + `CACHE_TYPE=local`. |
| Python   | pytest    | `pytest` | run from `src/` (tests import `from app import app`) |
| C#       | xUnit     | `dotnet test` | from `src/tests/` (no .sln; the test csproj lives there) |
| Node.js  | Jest      | `npm test` | run from `src/` for web plain; from project root for Cli |
| Ruby     | Rails     | `rails test` | from `src/` |
| Elixir   | ExUnit    | `mix test` | run from `src/` (mix project) |

Notes:
- Python/Node plain tests import via `src/`, so `pytest` / `npm test` must be executed inside `src/`, not the framework folder.
- DB-backed integration tests need `DB_*` env vars; use `DB_DRIVER=sqlite` + `DB_FILE=test.db` for test environments.

## Local CI (multi-database)

`scripts/ci-local.sh` runs the full CI matrix inside Podman containers, booting
disposable Postgres 16, MariaDB 11 (mysql), SQL Server 2022 (sqlserver) and MongoDB 7
on an isolated `ci-local-net` network. It is invoked per job (or `all`):
- `./scripts/ci-local.sh php`, `node`, `python`, `ruby`, `csharp`, `java`, `elixir`, `all`.

Per-language driver matrix (each project is exercised against every driver it
actually supports; projects that reject a driver — e.g. a Prisma `provider =
"postgresql"` schema — are reported as *skipped*, not failed):
- PHP: `sqlite pgsql mysql mongodb` (PHP 8.2-cli lacks pdo_sqlsrv, so `sqlserver` is excluded; requires ≥8.3).
- Node / Python / C#: `sqlite pgsql mysql sqlserver mongodb`.
- Java: `sqlite pgsql mysql sqlserver` (no MongoDB JDBC driver in `DataSourceConfig`); the runner keeps a persistent `ci-local-m2` Maven volume and forces `-XX:-TieredCompilation` because Temurin 21.0.11's C1 JIT crashes on `ConcurrentHashMap::putVal`.
- Elixir: `sqlite pgsql mysql sqlserver mongodb` (Ecto adapters: ecto_sqlite3/postgrex/myxql/tds/mongodb_ecto).
- Ruby: `sqlite` (Rails, on PostgreSQL/MariaDB hosts where tested).

The `sqlserver` jobs use the `mcr.microsoft.com/mssql/server:2022-latest` image, which
defaults to encrypted connections. Clients invoke `sqlcmd -C` (trust server certificate)
to connect without configuring a custom CA. In GitHub Actions the runner also installs
`mssql-tools18` via apt, pinned to the runner's Ubuntu version
(`$(. /etc/os-release; echo $VERSION_ID)`) and made best-effort (`|| true`) so a missing
Microsoft apt repo does not fail the job; local `ci-local.sh` runs instead use the
`sqlcmd` shipped inside the mssql container, so no host-side install is needed there.

At startup the script runs `podman container prune -f` to remove every **stopped**
container (not just the `ci-local-*` ones) left over from previous runs; a trap cleans
the `ci-local-*` containers + network on exit.

## Editing Rules

1. **Do not change** ORM framework structure (C# Web uses EF Core; others use their respective ORMs)
2. **Do not add** C# namespaces — use classes in the global namespace
3. **Do not use** autoload in PHP — use `require_once` with relative paths
4. **Do not change** table names, column names, or business logic
5. **Follow** the existing pattern (Adapter for PHP/Python/Node/Ruby; DbContext for C# Web)
6. **Indentation**: PHP/Python/C# = 4 spaces; JS/CSS/HTML/Ruby = 2 spaces
7. **Do not add** comments unless requested
8. **Verify** `Test-Path` before creating directories; use `New-Item -ItemType Directory -Force`
9. **Default DB**: PostgreSQL. **Default cache**: Redis with Local fallback
10. **Run Tests**: run the relevant tests for touched projects; broader tests only for shared conventions, cross-project changes, or high-risk edits
11. **Environment examples**: keep `.env.example` aligned with documented DB/cache variables
12. **Review tests after every change**: whenever a task finishes, review (and run) all tests for that change to validate nothing is broken — see Verification Strategy
13. **Branches**: Always create a new branch from main for new changes so they can be reviewed before merging. Name it after the scope: `feat/<language>` for a new language port, `feat/<project>` for a project feature, `fix/<short-description>` for fixes.
14. **Spec-first workflow**: always build the plan from `Specs/<Project>/spec.md` first. If the plan changes behavior, update the spec before touching code.
15. **Tests before code**: define the tests the spec requires before implementing, then implement until they pass.
16. **All tests green before push**: never commit or push changes until every test for the touched projects passes (`mix test`, `pytest`, `dotnet test`, `npm test`, `rails test`, etc.). If a blocker prevents running tests, report it instead of pushing.

## Verification Strategy

- **Every change must be validated by its tests before being marked done.** After finishing any code change, run the relevant test command(s) for the touched language/project and confirm they pass (or clearly report blockers).
- Documentation-only changes: run `rg` checks for stale terms or contradictions.
- Container changes: run `podman compose config` in the touched project when possible.
- Code changes: run the relevant test command for the touched language/project.
- Cross-project shared changes: run a broader sample across affected languages/frameworks.
- If a verification command cannot run because dependencies or services are unavailable, report that clearly.
