
# 💼 Professional Software Development Portfolio

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Languages](https://img.shields.io/badge/languages-PHP%20%7C%20Python%20%7C%20C%23%20%7C%20Node.js%20%7C%20Ruby-blue)
![Podman](https://img.shields.io/badge/containerized-Podman-892CA0)

A portfolio of software projects where I implement **the same set of applications across multiple languages and frameworks** (PHP, Python, C#, Node.js and Ruby), keeping consistent architecture throughout: the **Adapter** pattern for persistence, **Factory** for driver selection, two-level caching (Redis/local), and unit tests in every implementation.

The goal is twofold: to compare how the same problem is solved across different ecosystems, and to demonstrate mastery of design patterns, best practices (SOLID, clean code), and infrastructure-agnostic architecture.

👤 **Eduar Carvajal** — [LinkedIn](https://www.linkedin.com/in/carvajaldiazeduar) · [Email](carvajaldiazeduar@gmail.com)

---

## ✅ Prerequisites

- Podman with Compose support (`podman compose`)
- PHP 8+, Composer and PHPUnit for PHP projects
- Python 3.11+ and pytest for Python projects
- .NET 9 SDK for C# projects
- Node.js 20+ and npm for Node.js projects
- Ruby 3+ and Bundler for Ruby on Rails projects

PostgreSQL and Redis are started by the compose files for web projects. If you run projects without containers, install and configure those services locally or switch to SQLite/local cache where supported.

---

## 🚀 Quick Start

Want to explore something quickly? Pick your entry point:

- **See a full CRUD project with DB + cache:**
  ```bash
  cd Contacts/Python/Web/FastAPI
  podman compose up
  ```
- **See the Adapter pattern in action (no ORM, direct connection):**
  → `PHP/Web/Plain/src/Storage/` or `Python/Web/Plain/src/storage/`
- **See an ETL data pipeline with a configurable warehouse:**
  → `DataPipeline/Python/Web/Plain`
- **See semantic search over a vector store:**
  → `SemanticSearch/Python/Web/Flask` or `SemanticSearch/Node.js/Web/Plain`
- **See local cloud services:**
  → `CloudLocal` (AWS LocalStack, GCP emulators, Azure Azurite/Cosmos DB)
- **See an API Gateway with JWT and rate limiting:**
  → `APIGateway/Node.js/Web/Plain`

---

## ▶️ How to Run a Project

Choose any web implementation, enter its folder, and start the stack with Podman:

```bash
cd Contacts/Python/Web/FastAPI
podman compose up
```

Rebuild images after dependency or container changes:

```bash
podman compose up --build
```

Stop the stack:

```bash
podman compose down
```

Use `.env.example` as a reference for database and cache variables. Compose files already provide the usual PostgreSQL + Redis setup for local development.

---

## 📁 Structure

Every project with persistence follows the same folder pattern (Storage/Cache with an interface + Factory + Adapters). Here's a full example (PHP Plain); every other language replicates this same logic adapted to its own syntax.

<details>
<summary><strong>View full structure tree</strong></summary>

```
Project/
├── PHP/
│   ├── Cli/
│   └── Web/
│       ├── Laravel/
│       ├── Symfony/
│       └── Plain/
│           ├── src/
│           │   ├── Storage/
│           │   │   ├── DatabaseAdapter.php      ← interface
│           │   │   ├── DatabaseFactory.php
│           │   │   └── Adapters/
│           │   │       ├── PostgreSQL.php
│           │   │       ├── MySQL.php
│           │   │       ├── SQLite.php
│           │   │       ├── SQLServer.php
│           │   │       └── MongoDB.php
│           │   ├── Cache/
│           │   │   ├── CacheAdapter.php          ← interface
│           │   │   ├── CacheFactory.php
│           │   │   └── Adapters/
│           │   │       ├── Redis.php
│           │   │       └── Local.php
│           │   ├── index.php
│           │   └── template.html
│           ├── Dockerfile
│           └── docker-compose.yml
├── Python/
│   ├── Cli/
│   ├── Reflex/
│   └── Web/
│       ├── Flask/                 ← SQLAlchemy + cache.py
│       ├── FastAPI/               ← async SQLAlchemy
│       ├── Django/                ← Django ORM
│       └── Plain/
│           ├── src/
│           │   ├── storage/
│           │   │   ├── __init__.py
│           │   │   ├── database_adapter.py       ← ABC
│           │   │   ├── database_factory.py
│           │   │   └── adapters/
│           │   │       ├── __init__.py
│           │   │       ├── postgresql.py
│           │   │       ├── mysql.py
│           │   │       ├── sqlite.py
│           │   │       ├── sqlserver.py
│           │   │       └── mongodb.py
│           │   ├── cache/
│           │   │   ├── __init__.py
│           │   │   ├── cache_adapter.py          ← ABC
│           │   │   ├── cache_factory.py
│           │   │   └── adapters/
│           │   │       ├── __init__.py
│           │   │       ├── redis.py
│           │   │       └── local.py
│           │   ├── app.py
│           │   ├── templates/index.html
│           │   └── requirements.txt
│           ├── Dockerfile
│           └── docker-compose.yml
├── CSharp/
│   ├── Cli/
│   └── Web/
│       ├── AspNetMinimalApi/      ← IDatabaseAdapter + ICacheAdapter
│       │   └── src/
│       │       ├── Storage/
│       │       │   ├── IDatabaseAdapter.cs
│       │       │   ├── DatabaseFactory.cs
│       │       │   └── Adapters/
│       │       │       ├── PostgreSQL.cs
│       │       │       ├── MySQL.cs
│       │       │       ├── SQLite.cs
│       │       │       ├── SQLServer.cs
│       │       │       └── MongoDB.cs
│       │       ├── Cache/
│       │       │   ├── ICacheAdapter.cs
│       │       │   ├── CacheFactory.cs
│       │       │   └── Adapters/
│       │       │       ├── Redis.cs
│       │       │       └── Local.cs
│       │       ├── Services/
│       │       │   ├── ContactService.cs          ← per project
│       │       │   └── Contact.cs                 ← model
│       │       ├── Program.cs
│       │       └── wwwroot/
│       ├── Blazor/                 ← same pattern as AspNetMinimalApi
│       └── MAUI/
├── Ruby/
│   ├── Cli/
│   └── Web/
│       └── RubyOnRails/            ← Rails full MVC + ERB + ActiveRecord
│           ├── src/
│           │   ├── app/
│           │   │   ├── controllers/
│           │   │   ├── models/
│           │   │   └── views/
│           │   ├── config/
│           │   │   ├── application.rb    ← DatabaseUrl.build (ENV["DATABASE_URL"])
│           │   │   ├── database.yml      ← only `url: <%= ENV["DATABASE_URL"] %>`
│           │   │   ├── routes.rb
│           │   │   └── initializers/cache.rb
│           │   ├── db/migrate/
│           │   ├── config.ru
│           │   └── Gemfile
│           ├── Dockerfile
│           └── docker-compose.yml
├── Node.js/
│   ├── Cli/
│   └── Web/
│       ├── Express/               ← Prisma + cache.js
│       ├── React/
│       ├── NextJS/
│       └── Plain/
│           ├── src/
│           │   ├── storage/
│           │   │   ├── DatabaseAdapter.js        ← base class
│           │   │   ├── DatabaseFactory.js
│           │   │   └── adapters/
│           │   │       ├── PostgreSQL.js
│           │   │       ├── MySQL.js
│           │   │       ├── SQLite.js
│           │   │       ├── SQLServer.js
│           │   │       └── MongoDB.js
│           │   ├── cache/
│           │   │   ├── CacheAdapter.js           ← base class
│           │   │   ├── CacheFactory.js
│           │   │   └── adapters/
│           │   │       ├── Redis.js
│           │   │       └── Local.js
│           │   ├── server.js
│           │   └── public/
│           ├── Dockerfile
│           └── docker-compose.yml
├── APIGateway/
│   └── Node.js/
│       └── Web/
│           └── Plain/
│               ├── src/
│               │   ├── middleware/
│               │   │   ├── auth.js          ← JWT validation
│               │   │   ├── rateLimit.js     ← Token bucket rate limiting
│               │   │   └── proxy.js         ← Service routing
│               │   ├── cache/
│               │   │   ├── CacheAdapter.js
│               │   │   ├── CacheFactory.js
│               │   │   └── adapters/
│               │   │       ├── Redis.js
│               │   │       └── Local.js
│               │   ├── server.js
│               │   └── public/
│               ├── Dockerfile
│               └── docker-compose.yml
├── EventProcessor/
│   └── Node.js/
│       └── Web/
│           └── Plain/
│               ├── src/
│               │   ├── queue/
│               │   │   ├── QueueAdapter.js          ← base class
│               │   │   ├── QueueFactory.js
│               │   │   └── adapters/
│               │   │       ├── RabbitMQ.js
│               │   │       ├── Kafka.js
│               │   │       ├── SQS.js
│               │   │       └── Redis.js
│               │   ├── server.js
│               │   ├── worker.js
│               │   └── public/
│               ├── Dockerfile
│               └── docker-compose.yml
├── DataPipeline/
│   └── Python/
│       └── Web/
│           └── Plain/
│               ├── src/
│               │   ├── storage/
│               │   │   ├── warehouse_adapter.py     ← ABC
│               │   │   ├── warehouse_factory.py
│               │   │   └── adapters/
│               │   │       ├── duckdb.py            ← default
│               │   │       ├── bigquery.py
│               │   │       └── postgresql.py
│               │   ├── cache/
│               │   │   ├── cache_adapter.py         ← ABC
│               │   │   ├── cache_factory.py
│               │   │   └── adapters/
│               │   │       ├── redis.py
│               │   │       └── local.py
│               │   ├── app.py
│               │   ├── templates/
│               │   └── requirements.txt
│               ├── Dockerfile
│               └── docker-compose.yml
├── SemanticSearch/
│   ├── Cli/  (per language)
│   └── Web/
│       ├── Plain/       ← VectorStoreAdapter + CacheAdapter
│       │   └── src/
│       │       ├── storage/
│       │       │   ├── VectorAdapter.js/.py/.php    ← interface/ABC
│       │       │   ├── VectorFactory.js/.py/.php
│       │       │   └── adapters/
│       │       │       ├── ChromaDB.js/.py/.php     ← default
│       │       │       ├── PgVector.js/.py/.php
│       │       │       └── Pinecone.js/.py/.php
│       │       ├── cache/   ← CacheAdapter + Redis/Local
│       │       ├── server.js/app.py/index.php
│       │       └── public/ or templates/
│       ├── Express/Flask/FastAPI/Django/Laravel/Symfony/RubyOnRails/NextJS/React/
│       └── AspNetMinimalApi/Blazor/  (C# inline adapters in Program.cs)
└── CloudLocal/
    ├── docker-compose.yml          ← AWS, GCP and Azure local emulator profiles
    ├── aws/
    │   └── localstack/
    │       └── pipeline/           ← LocalStack + Terraform + Node.js pipeline demo
    ├── gcp/
    │   ├── pubsub/
    │   ├── firestore/
    │   ├── bigtable/
    │   └── storage/
    ├── azure/
    │   ├── azurite/
    │   └── cosmosdb/
    └── shared/
        ├── scripts/
        └── healthchecks/
```

</details>

---

## 🧩 Projects

| Project | Description |
|---|---|
| **Calculator** | Calculator with basic operations (add, subtract, multiply, divide). No persistence. |
| **Chronometer** | Digital stopwatch. No persistence. |
| **Contacts** | Contact manager (CRUD) with **database + cache**. |
| **Conversor** | Unit converter (length, weight, temperature). No persistence. |
| **Inboxes** | Inbox system with **database + cache**. |
| **PasswordGenerator** | Secure password generator with **history persisted in DB + cache**. |
| **TasksList** | Task list (CRUD) with **database + cache**. |
| **APIGateway** | Lightweight proxy/gateway with JWT validation, rate limiting (Redis/Token Bucket), and service routing. |
| **EventProcessor** | Async job queue processor with RabbitMQ/Kafka/SQS/Redis support, retry mechanisms, and dead-letter queues. |
| **DataPipeline** | Configurable ETL data pipeline: ingest from CSV/JSON, transform and load into a warehouse (duckdb/bigquery/postgresql). |
| **SemanticSearch** | Semantic search over documents using a vector store (chromadb/pgvector/pinecone) with embeddings and similarity search. |
| **CloudLocal** | Local cloud service lab for AWS, GCP and Azure using LocalStack, Google Cloud SDK emulators, fake-gcs-server, Azurite and Cosmos DB Emulator. |

---

## 📊 Project Status

| Project | CLI | Web | DB + Cache | Containers |
|---|---|---|---|---|
| Calculator | Yes | Yes | No | Yes |
| Chronometer | Yes | Yes | No | Yes |
| Contacts | Yes | Yes | Yes | Yes |
| Conversor | Yes | Yes | No | Yes |
| Inboxes | Yes | Yes | Yes | Yes |
| PasswordGenerator | Yes | Yes | Yes | Yes |
| TasksList | Yes | Yes | Yes | Yes |
| APIGateway | No | Yes | Cache | Yes |
| EventProcessor | No | Yes | Queue + Cache | Yes |
| DataPipeline | No | Yes | Warehouse + Cache | Yes |
| SemanticSearch | Yes | Yes | Vector store + Cache | Yes |
| CloudLocal | No | Local services | AWS/GCP/Azure emulators | Yes |

---

## 🧱 Architecture Principles

- Same domain behavior across languages and frameworks.
- Adapter pattern for persistence and cache in plain implementations.
- Factory pattern for runtime driver selection.
- PostgreSQL as the default database, with MySQL, SQLite, SQL Server and MongoDB support where implemented.
- Redis as the preferred cache, with local in-memory fallback.
- Separate CLI and Web implementations to compare interaction styles.
- Containers are runtime infrastructure, not business logic.

---

## 🛠️ Technologies

Each web project uses a different framework, with its own subfolder under `Web/(framework)/src/`.

### ORM frameworks

| Language | Frameworks | ORM | Cache |
|----------|-----------|-----|-------|
| **PHP** | Laravel, Symfony | Eloquent / Doctrine | Redis / Local |
| **Python** | Flask, FastAPI, Django | SQLAlchemy / Django ORM | Redis / Local |
| **C#** | _(none — see note below)_ | — | — |
| **Node.js** | Express | Prisma | Redis / Local |
| **Ruby** | RubyOnRails | ActiveRecord | Redis / Local |

> **Note:** C# doesn't include a "full-ORM" framework (like Laravel/Django) because Blazor and MAUI focus on UI/client concerns; instead, both follow the same Adapter pattern as the plain ASP.NET Minimal API version, keeping consistency with the rest of the repo.

### Plain code frameworks (no ORM, direct connection)

| Language | Framework | DB Adapter | Drivers | Cache |
|----------|-----------|-----------|---------|-------|
| **PHP** | Plain | DatabaseAdapter (interface) | PostgreSQL, MySQL, SQLite, SQL Server, MongoDB | Redis / Local |
| **Python** | Plain | DatabaseAdapter (ABC) | PostgreSQL, MySQL, SQLite, SQL Server, MongoDB | Redis / Local |
| **C#** | AspNetMinimalApi | IDatabaseAdapter (interface) | PostgreSQL, MySQL, SQLite, SQL Server, MongoDB | Redis / Local |
| **C#** | Blazor | IDatabaseAdapter (interface) | PostgreSQL, MySQL, SQLite, SQL Server, MongoDB | Redis / Local |
| **Node.js** | Plain | DatabaseAdapter (base class) | PostgreSQL, MySQL, SQLite, SQL Server, MongoDB | Redis / Local |
| **Node.js** | Plain (APIGateway) | CacheAdapter (base class) | Redis (rate limiting) | Redis / Local |
| **Node.js** | Plain (APIGateway, EventProcessor, CloudLocal AWS pipeline) | DatabaseAdapter (base class) + QueueAdapter | Redis/BullMQ, RabbitMQ, Kafka, SQS | Redis / Local |
| **Python** | Plain (DataPipeline) | DataWarehouseAdapter (ABC) | duckdb (default), BigQuery, PostgreSQL | Redis / Local |
| **multi** | Plain (SemanticSearch) | VectorStoreAdapter (interface/ABC/base) | chromadb (default), pgvector, pinecone | Redis / Local |

---

## 🗄️ Database

Projects with persistence use an **ORM** in the full frameworks and **direct connection** in the plain variants.

The **plain** variants implement the **Adapter** pattern with a base interface/class and one implementation per database engine, selected at runtime via `DatabaseFactory` based on `DB_DRIVER`.

| Project | ORM (frameworks) | Plain (adapter pattern) | Models |
|----------|-----------------|------------------------|---------|
| Contacts | Eloquent / SQLAlchemy / Prisma / ActiveRecord | DatabaseAdapter → PostgreSQL / MySQL / SQLite / SQL Server / MongoDB | `Contact` (name, phone, email) |
| Inboxes | Eloquent / SQLAlchemy / Prisma / ActiveRecord | DatabaseAdapter → 5 drivers | `Message` (sender, subject, body, read) |
| PasswordGenerator | Eloquent / SQLAlchemy / Prisma / ActiveRecord | DatabaseAdapter → 5 drivers | `PasswordEntry` (password, length) |
| TasksList | Eloquent / SQLAlchemy / Prisma / ActiveRecord | DatabaseAdapter → 5 drivers | `Task` (title, description, completed) |
| CloudLocal AWS pipeline | _(none)_ | DatabaseAdapter → PostgreSQL / MySQL / SQLite / SQL Server / MongoDB / DynamoDB | `FileMetadata` (fileName, fileType, status, key) |
| DataPipeline | _(none)_ | DataWarehouseAdapter → duckdb (default) / bigquery / postgresql | `SourceRecord` (source, data, processed) |
| SemanticSearch | _(none)_ | VectorStoreAdapter → chromadb (default) / pgvector / pinecone | `Document` (id, text, embedding, metadata) |

### Supported databases

Connection via environment variables `DB_DRIVER`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`:

| Database | Driver | Default port |
|---------------|--------|---------------|
| **PostgreSQL** (default) | `pgsql` / `postgresql` | `5432` |
| MySQL / MariaDB | `mysql` | `3306` |
| SQL Server | `sqlserver` / `mssql` | `1433` |
| MongoDB | `mongodb` | `27017` |
| SQLite | `sqlite` | — (uses `DB_FILE`) |
| **DynamoDB** (AWS simulation) | `dynamodb` | — (uses `AWS_ENDPOINT_URL`) |

---

## ⚡ Cache

A two-level **cache adapter** pattern is implemented (same `CacheAdapter` interface, with Redis and local implementations):

| Level | Implementation | Requirement |
|-------|---------------|-----------|
| **Redis** (preferred) | redis-py / ioredis / StackExchange.Redis / \Redis | Redis server |
| **Local** (fallback) | dict / Map / ConcurrentDictionary / array | None |

Controlled by the environment variable `CACHE_TYPE`:
- `redis` (default) — Uses Redis. Falls back to local if there is no connection.
- `local` — Always uses the in-memory cache.

GET queries are cached with a configurable TTL (`CACHE_TTL`, default 300s). Write operations (POST, PUT, DELETE) invalidate the cache automatically.

---

## ⚙️ Environment Variables

Common variables used by persistence and cache adapters:

```env
DB_DRIVER=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_NAME=app_db
DB_USER=postgres
DB_PASSWORD=postgres
DB_FILE=app.db

CACHE_TYPE=redis
REDIS_HOST=redis:6379
CACHE_TTL=300
```

See `.env.example` for a reusable template. Ruby on Rails projects build `DATABASE_URL` internally from these values where needed.

---

## 🐳 Podman

Each web framework includes `Dockerfile`, `docker-compose.yml` and `.dockerignore`. The repository keeps those standard OCI-compatible filenames, but the intended runtime is Podman. The compose files start the app, PostgreSQL (active), and Redis, with MySQL, SQL Server and MongoDB commented out for optional use. `CloudLocal` additionally includes local AWS, GCP and Azure service emulators. C# images are `.NET 9 Alpine` (`mcr.microsoft.com/dotnet/{sdk,aspnet}:9.0-alpine`).

| Framework | Port | Command |
|-----------|--------|---------|
| PHP Plain | `8000` | `podman compose up` |
| PHP Laravel | `8000` | `podman compose up` |
| PHP Symfony | `8000` | `podman compose up` |
| Python Plain | `5000` | `podman compose up` |
| Python Flask | `5000` | `podman compose up` |
| Python Django | `8000` | `podman compose up` |
| Python FastAPI | `8000` | `podman compose up` |
| Python Reflex | `3000` | `podman compose up` |
| C# AspNetMinimalApi | `5000` | `podman compose up` |
| C# Blazor | `5000` | `podman compose up` |
| Node.js Plain | `3000` | `podman compose up` |
| Node.js Express | `3000` | `podman compose up` |
| Node.js React (Vite) | `5173` | `podman compose up` |
| Node.js NextJS | `3000` | `podman compose up` |
| Ruby RubyOnRails | `3000` | `podman compose up` |
| **APIGateway (Plain)** | `3000` | `podman compose up` |
| **EventProcessor (Plain)** | `3000` | `podman compose up` (adds Prometheus on `9090` and Grafana on `3001` for metrics) |
| **DataPipeline (Plain)** | `5000` | `podman compose up` |
| **SemanticSearch (Plain/Flask/Express)** | `5000` | `podman compose up` (adds a `chroma` service) |
| **SemanticSearch (Laravel/Django/Rails)** | `8000` | `podman compose up` |
| **SemanticSearch (NextJS/React)** | `3000`/`5173` | `podman compose up` |
| **SemanticSearch (C#)** | `80`/`8000` | `podman compose up` |

Example:
```bash
cd Contacts/Python/Web/Plain
podman compose up
```

> **Why not rename to `Podmanfile`?** Podman can build standard `Dockerfile` files, and keeping `Dockerfile` + `docker-compose.yml` preserves compatibility with OCI tooling, IDEs and CI systems.

---

## 📐 Conventions

- **Separate files**: JS, CSS and HTML in independent files per framework.
- **Indentation**: 4 spaces for PHP, Python, C#; 2 spaces for Node.js/React/Express/Ruby.
- **ORM** used in full frameworks (Laravel, Symfony, Flask, FastAPI, Django, Express, RubyOnRails). **Adapter pattern** (DatabaseAdapter + 5 drivers) in plain variants.
- **Cache**: CacheAdapter (interface) with RedisCache (default) and LocalCache (fallback) in plain; Redis/Local via `cache.py` in ORM frameworks; `Rails.cache` (redis_cache_store with memory_store fallback) in RubyOnRails.
- **DB config**: individual variables `DB_DRIVER`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_FILE` (SQLite). `DATABASE_URL` is not used in plain. In RubyOnRails, `database.yml` uses `url: <%= ENV["DATABASE_URL"] %>` (URL built by `DatabaseUrl.build` in `application.rb`).
- **Design patterns**: Adapter (DB, Cache), Factory, SOLID, clean code.

---

## 🧪 Tests

Each implementation includes unit tests using the standard framework for each language:

| Language | Framework | Command |
|----------|-----------|---------|
| PHP | PHPUnit (frameworks) / assert (Plain CLI + Web) | `vendor/bin/phpunit` · Plain: `php -d zend.assertions=1 -d assert.exception=1 tests/*Test.php` (Web contra `php -S 127.0.0.1:8000 index.php`) |
| Python | pytest | `pytest` |
| C# | xUnit | `dotnet test` |
| Node.js | Jest | `npm test` |
| Ruby | RubyOnRails | `rails test` |

> **Note:** database-backed projects require the `DB_DRIVER`, `DB_*` variables set for integration tests. Use `DB_DRIVER=sqlite` with `DB_FILE=test.db` for test environments.

Examples:

```bash
cd Contacts/Python/Web/FastAPI
pytest
```

```bash
cd Contacts/Node.js/Web/Plain
npm test
```

```bash
cd Contacts/CSharp/Web/AspNetMinimalApi
dotnet test
```

```bash
cd Contacts/Ruby/Web/RubyOnRails/src
rails test
```

### Running CI locally with only Podman

The GitHub Actions workflow (`.github/workflows/ci.yml`) can be reproduced locally without installing any language toolchains. `scripts/ci-local.sh` runs the same 5 jobs (node, python, php, ruby, csharp) inside Podman containers, booting disposable Postgres 16, MariaDB 11 (mysql), SQL Server 2022 (sqlserver) and MongoDB 7 on an isolated `ci-local-net` network (these won't conflict with a local PostgreSQL on `:5432`). At startup it removes every stopped Podman container (`podman container prune -f`) so leftover containers from previous runs don't interfere:

```bash
./scripts/ci-local.sh          # run all CI jobs
./scripts/ci-local.sh node     # run a single job
```

Per-language driver matrix (projects that don't support a given driver are skipped, not failed):

| Language | Drivers exercised |
|:---:|---|
| PHP | `sqlite pgsql mysql mongodb` (pdo_sqlsrv needs PHP ≥ 8.3, so `sqlserver` is excluded on `php:8.2`) |
| Node / Python / C# | `sqlite pgsql mysql sqlserver mongodb` |
| Ruby | `sqlite` (Rails; plain Ruby uses SQLite) |

---

## 🛠️ Troubleshooting

| Problem | Suggested fix |
|---|---|
| `podman compose` is not found | Install Podman Compose support or use the Podman Desktop bundled compose integration. |
| A port is already in use | Stop the conflicting service or change the exposed port in the local compose file. |
| PostgreSQL connection fails | Confirm `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD` and that the database service is running. |
| Redis connection fails | Use `CACHE_TYPE=local` temporarily or confirm `REDIS_HOST=redis:6379` inside containers. |
| Windows path or volume issues | Run from the project folder and ensure Podman has access to the workspace directory. |
| LocalStack socket errors | Check the `CloudLocal/aws/localstack/pipeline` compose file because LocalStack may require a Docker-compatible socket when simulating some AWS services. |

---

## 💡 Learnings & Roadmap

- Implementing the same domain (e.g. `Contacts`) across 5 different languages made it easier to directly compare ORM handling, dependency injection, and environment-based configuration.
- The Adapter pattern kept business logic fully decoupled from the chosen database engine, making it straightforward to switch from PostgreSQL to MongoDB without touching the rest of the code.

**Next steps:**
- [x] CI/CD with GitHub Actions (build + test per project)
- [x] Observability and metrics (Prometheus/Grafana) in EventProcessor
- [x] API documentation (OpenAPI/Swagger) for the REST projects

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](./LICENSE) for details.
