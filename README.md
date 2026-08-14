# 💼 Professional Software Development Portfolio

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Languages](https://img.shields.io/badge/languages-PHP%20%7C%20Python%20%7C%20C%23%20%7C%20Node.js%20%7C%20Ruby%20%7C%20Java%20%7C%20Elixir-blue)
![Podman](https://img.shields.io/badge/containerized-Podman-892CA0)

A portfolio of software projects where I implement **the same set of applications across multiple languages and frameworks** (PHP, Python, C#, Node.js, Ruby, Java, Elixir), keeping consistent architecture throughout: the **Adapter** pattern for persistence, **Factory** for driver selection, two-level caching (Redis/local), and unit tests in every implementation.

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
- Java 21+ and Maven for Java projects
- Elixir 1.17+ and Mix for Elixir projects

PostgreSQL and Redis are started by the compose files for web projects. If you run projects without containers, install and configure those services locally or switch to SQLite/local cache where supported.

---

## 🧩 Projects

Every project folder ships its own `README.md` with **architecture, patterns, logic, endpoints, env vars and tests** — the table below links to them. The [specs](Specs/) document the full contract per project.

| Project | Description |
|---|---|
| [**Calculator**](Calculator/README.md) | Basic arithmetic (add, subtract, multiply, divide). No persistence. |
| [**Chronometer**](Chronometer/README.md) | Digital stopwatch with start/pause/resume/reset/lap. No persistence. |
| [**Contacts**](Contacts/README.md) | Contact manager (CRUD) with **database + cache**. |
| [**Conversor**](Conversor/README.md) | Unit converter (length, mass, temperature, currency). No persistence. |
| [**Inboxes**](Inboxes/README.md) | Message inbox (CRUD) with **database + cache**. |
| [**PasswordGenerator**](PasswordGenerator/README.md) | Secure password generator with **history persisted in DB + cache**. |
| [**TasksList**](TasksList/README.md) | Task list (CRUD) with **database + cache**. |
| [**APIGateway**](APIGateway/README.md) | Lightweight proxy/gateway with JWT validation, rate limiting, and service routing. |
| [**EventProcessor**](EventProcessor/README.md) | Async job queue processor (Redis/RabbitMQ/Kafka/SQS) with worker + observability. |
| [**DataPipeline**](DataPipeline/README.md) | Configurable ETL pipeline into a warehouse (duckdb/bigquery/postgresql). |
| [**SemanticSearch**](SemanticSearch/README.md) | Semantic search over documents via a vector store (chromadb/pgvector/pinecone). |
| [**CloudLocal**](CloudLocal/README.md) | Local cloud service lab for AWS, GCP and Azure (LocalStack, emulators, Azurite, Cosmos DB). |
| [**ChatAI**](ChatAI/README.md) | AI chat API routing to a swappable LLM provider (OpenAI-compatible, Azure, Google, Anthropic). Stateless. |

---

## 🚀 Quick Start

Pick any web implementation, enter its folder, and start the stack with Podman:

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

Every project follows the same shape:

```
Project/{Language}/{Cli,Web}/{Framework}/src/
```

Persistence-backed projects use the **Adapter + Factory** pattern: a `DatabaseAdapter` interface/ABC/base class with one implementation per driver (`PostgreSQL`, `MySQL`, `SQLite`, `SQLServer`, `MongoDB`), selected at runtime via `DatabaseFactory` from `DB_DRIVER`. Cache uses the same pattern (`CacheAdapter` + `CacheFactory`) with Redis and a local in-memory fallback, selected via `CACHE_TYPE`.

Specialized projects swap the persistence adapter for their own:
- **DataPipeline** → `DataWarehouseAdapter` (duckdb/bigquery/postgresql)
- **SemanticSearch** → `VectorStoreAdapter` (chromadb/pgvector/pinecone)
- **EventProcessor** → `QueueAdapter` (redis/rabbitmq/kafka/sqs)
- **APIGateway** → cache only (rate limiting), no DB
- **ChatAI** → `IChatProvider` abstraction over LLM providers, no DB/cache

The detailed architecture of each project (diagrams, adapters, data model, endpoints, logic) lives in the project's own `README.md`.

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
| ChatAI | No | Yes | No | Yes |

---

## 🧱 Architecture Principles

- Same domain behavior across languages and frameworks.
- Adapter pattern for persistence, cache, queue, warehouse and vector store in plain implementations.
- Factory pattern for runtime driver selection.
- PostgreSQL as the default database, with MySQL, SQLite, SQL Server and MongoDB support where implemented.
- Redis as the preferred cache, with local in-memory fallback.
- Separate CLI and Web implementations to compare interaction styles.
- Containers are runtime infrastructure, not business logic.

---

## 🛠️ Technologies

### ORM frameworks

| Language | Frameworks | ORM | Cache |
|----------|-----------|-----|-------|
| **PHP** | Laravel, Symfony | Eloquent / Doctrine | Redis / Local |
| **Python** | Flask, FastAPI, Django | SQLAlchemy / Django ORM | Redis / Local |
| **Node.js** | Express | Prisma | Redis / Local |
| **Ruby** | RubyOnRails | ActiveRecord | Redis / Local |
| **C#** | AspNetMinimalApi, Blazor | EF Core | Redis / Local |
| **Java** | Spring Boot | JPA/Hibernate | Redis / Local |
| **Elixir** | Phoenix | Ecto | Redis / Local |

### Plain code frameworks (no ORM, direct connection)

| Language | Framework | Adapter | Drivers | Cache |
|----------|-----------|---------|---------|-------|
| **PHP / Python / Node.js** | Plain | DatabaseAdapter (interface/ABC/base) | PostgreSQL, MySQL, SQLite, SQL Server, MongoDB | Redis / Local |
| **Node.js** | Plain (APIGateway) | CacheAdapter (rate limiting) | Redis | Redis / Local |
| **Node.js** | Plain (EventProcessor) | QueueAdapter | Redis, RabbitMQ, Kafka, SQS | Redis / Local |
| **Python** | Plain (DataPipeline) | DataWarehouseAdapter | duckdb (default), BigQuery, PostgreSQL | Redis / Local |
| **multi** | Plain (SemanticSearch) | VectorStoreAdapter | chromadb (default), pgvector, pinecone | Redis / Local |
| **multi** | Plain (ChatAI) | IChatProvider + ChatProviderFactory | openai/openai-compatible (default), azure, google, anthropic | None |

---

## 🗄️ Database & ⚡ Cache

Projects with persistence use an **ORM** in the full frameworks and **direct connection** in the plain variants, always behind the same env-driven configuration.

Connection via environment variables `DB_DRIVER`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`:

| Database | Driver | Default port |
|---------------|--------|---------------|
| **PostgreSQL** (default) | `pgsql` / `postgresql` | `5432` |
| MySQL / MariaDB | `mysql` | `3306` |
| SQL Server | `sqlserver` / `mssql` | `1433` |
| MongoDB | `mongodb` | `27017` |
| SQLite | `sqlite` | — (uses `DB_FILE`) |
| **DynamoDB** (AWS simulation) | `dynamodb` | — (uses `AWS_ENDPOINT_URL`) |

Cache is a two-level **CacheAdapter** pattern controlled by `CACHE_TYPE`:
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

Specialized projects add their own variables (`WAREHOUSE_DRIVER`, `VECTOR_DRIVER`, `QUEUE_DRIVER`, `CHAT_PROVIDER`, etc.) — see each project's `README.md`. See `.env.example` for a reusable template. Ruby on Rails projects build `DATABASE_URL` internally from these values where needed.

---

## 🐳 Podman

Each web framework includes `Dockerfile`, `docker-compose.yml` and `.dockerignore`. The repository keeps those standard OCI-compatible filenames, but the intended runtime is Podman. The compose files start the app, PostgreSQL (active), and Redis, with MySQL, SQL Server and MongoDB commented out for optional use. `CloudLocal` additionally includes local AWS, GCP and Azure service emulators. C# images are `.NET 9 Alpine` (`mcr.microsoft.com/dotnet/{sdk,aspnet}:9.0-alpine`).

| Framework | Port | Command |
|-----------|--------|---------|
| PHP (Plain/Laravel/Symfony) | `8000` | `podman compose up` |
| Python (Plain/Flask) | `5000` | `podman compose up` |
| Python (Django/FastAPI) | `8000` | `podman compose up` |
| Python (Reflex) | `3000` | `podman compose up` |
| C# (AspNetMinimalApi/Blazor) | `5000` | `podman compose up` |
| Node.js (Plain/Express/NextJS) | `3000` | `podman compose up` |
| Node.js (React/Vite) | `5173` | `podman compose up` |
| Ruby (RubyOnRails) | `3000` | `podman compose up` |
| Java (Spring Boot) | `5000` | `podman compose up` |
| Elixir (Phoenix) | `4000` | `podman compose up` |
| **APIGateway (Plain)** | `3000` | `podman compose up` |
| **EventProcessor (Plain)** | `3000` | `podman compose up` (adds Prometheus on `9090` and Grafana on `3001`) |
| **DataPipeline (SpringBoot)** | `5000` | `podman compose up` |
| **SemanticSearch (Plain/Flask/Express)** | `5000` | `podman compose up` (adds a `chroma` service) |
| **SemanticSearch (Laravel/Django/Rails)** | `8000` | `podman compose up` |
| **SemanticSearch (NextJS/React)** | `3000`/`5173` | `podman compose up` |
| **ChatAI** | per impl (C#/Node/Ruby `3000`, Elixir `4000`, Java/Python `5000`, PHP `8000`) | `podman compose up` |

> **Why not rename to `Podmanfile`?** Podman can build standard `Dockerfile` files, and keeping `Dockerfile` + `docker-compose.yml` preserves compatibility with OCI tooling, IDEs and CI systems.

---

## 📐 Conventions

- **Separate files**: JS, CSS and HTML in independent files per framework.
- **Indentation**: 4 spaces for PHP, Python, C#; 2 spaces for Node.js/React/Express/Ruby.
- **ORM** used in full frameworks (Laravel, Symfony, Flask, FastAPI, Django, Express, RubyOnRails, EF Core, JPA, Ecto). **Adapter pattern** (DatabaseAdapter + 5 drivers) in plain variants.
- **Cache**: CacheAdapter (interface) with RedisCache (default) and LocalCache (fallback).
- **DB config**: individual variables `DB_DRIVER`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_FILE` (SQLite). `DATABASE_URL` is not used in plain. In RubyOnRails, `database.yml` uses `url: <%= ENV["DATABASE_URL"] %>`.
- **Design patterns**: Adapter (DB, Cache, Queue, Warehouse, Vector store), Factory, SOLID, clean code.

---

## 🧪 Tests

Each implementation includes unit tests using the standard framework for each language:

| Language | Framework | Command |
|----------|-----------|---------|
| PHP | PHPUnit (frameworks) / assert (Plain CLI + Web) | `vendor/bin/phpunit` · Plain: `php -d zend.assertions=1 -d assert.exception=1 tests/*Test.php` |
| Python | pytest | `pytest` |
| C# | xUnit | `dotnet test` |
| Node.js | Jest | `npm test` |
| Ruby | RubyOnRails | `rails test` |
| Java | JUnit 5 / Spring MockMvc | `mvn test` |
| Elixir | ExUnit | `mix test` |

> **Note:** database-backed projects require the `DB_DRIVER`, `DB_*` variables set for integration tests. Use `DB_DRIVER=sqlite` with `DB_FILE=test.db` for test environments.

### Running CI locally with only Podman

The GitHub Actions workflow (`.github/workflows/ci.yml`) can be reproduced locally without installing any language toolchains. `scripts/ci-local.sh` runs the same jobs (node, python, php, ruby, csharp, java) inside Podman containers, booting disposable Postgres 16, MariaDB 11 (mysql), SQL Server 2022 (sqlserver) and MongoDB 7 on an isolated `ci-local-net` network:

```bash
./scripts/ci-local.sh          # run all CI jobs
./scripts/ci-local.sh node     # run a single job
```

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

## 📄 License

This project is licensed under the MIT License — see [LICENSE](./LICENSE) for details.