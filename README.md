# 💼 Professional Software Development Portfolio

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Languages](https://img.shields.io/badge/languages-PHP%20%7C%20Python%20%7C%20C%23%20%7C%20Ruby%20%7C%20Java%20%7C%20Elixir%20%7C%20Go-blue)
![Podman](https://img.shields.io/badge/containerized-Podman-892CA0)

A portfolio of software projects where I implement **the same set of applications across multiple languages and frameworks** (PHP, Python, C#, Ruby, Java, Elixir, Go), keeping consistent architecture throughout: ORM-backed persistence within each framework, cache adapters, and unit tests in every implementation.

The goal is twofold: to compare how the same problem is solved across different ecosystems, and to demonstrate mastery of design patterns, best practices (SOLID, clean code), and infrastructure-agnostic architecture.

👤 **Eduar Carvajal** — [LinkedIn](https://www.linkedin.com/in/carvajaldiazeduar) · [Email](carvajaldiazeduar@gmail.com)

---

## ✅ Prerequisites

To **run** or **test** any project you only need **Podman with Compose support** (`podman compose`). Every web framework ships a `Dockerfile` + `docker-compose.yml`, so the language runtime, dependencies and services (PostgreSQL, Redis) are all provisioned inside the container — no host toolchain required.

The test scripts (`scripts/run-tests.ps1` / `scripts/run-tests.sh`) also require only Podman — they run .NET, Java and Python test suites inside ephemeral containers, using `CACHE_TYPE=local` and SQLite (`DB_DRIVER=sqlite`, `DB_FILE=/tmp/test.db`) for DB-backed projects, so no PostgreSQL or Redis is needed.

The language toolchains below are **only needed for local development without containers** (running or testing directly on the host):

- PHP 8+, Composer and PHPUnit for PHP projects
- Python 3.11+ and pytest for Python projects
- .NET 10 SDK for C# projects
- Ruby 3+ and Bundler for Ruby on Rails projects
- Java 21+ and Maven for Java projects
- Elixir 1.17+ and Mix for Elixir projects
- Go 1.22+ for Gin and Fiber projects

PostgreSQL and Redis are started by the compose files for web projects. If you run projects without containers, install and configure those services locally or switch to SQLite/local cache where supported. The CI matrix runs on GitHub Actions with Podman-compatible `docker-compose.yml` files.

---

## 🧩 Projects

Every project folder ships its own `README.md` with **architecture, patterns, logic, endpoints, env vars and tests** — the table below links to them.

| Project | Description |
|---|---|
| [**Inboxes**](Inboxes/README.md) | Message inbox (CRUD) with **database + cache**. |
| [**PasswordGenerator**](PasswordGenerator/README.md) | Secure password generator with **history persisted in DB + cache**. |
| [**SchoolNotes**](SchoolNotes/README.md) | School gradebook: students, teachers, courses, periods, enrollments and grades, with **JWT/Cookie auth + rate limiting**. |
| [**APIGateway**](APIGateway/README.md) | Lightweight proxy/gateway with JWT validation, rate limiting, and service routing. |
| [**EventProcessor**](EventProcessor/README.md) | Async job queue processor (Redis/RabbitMQ/Kafka/SQS) with worker + observability. |
| [**StreamVideo**](StreamVideo/README.md) | Serverless video pipeline (S3 → EventBridge → Step Functions → Batch/Rekognition → SQS → SNS) as CDK (Python), emulated against LocalStack. |
| [**DataPipeline**](DataPipeline/README.md) | Configurable ETL pipeline into a warehouse (duckdb/bigquery/postgresql). |
| [**SemanticSearch**](SemanticSearch/README.md) | Semantic search over documents via a vector store (chromadb/pgvector/pinecone). |
| [**CloudLocal**](CloudLocal/README.md) | Local cloud service lab for AWS, GCP and Azure (LocalStack, emulators, Azurite, Cosmos DB). |
| [**ChatAI**](ChatAI/README.md) | AI chat API routing to a swappable LLM provider (OpenAI-compatible, Azure, Google, Anthropic). Stateless. |

---

## 🚀 Quick Start

Pick any web implementation, enter its folder, and start the stack with Podman:

```bash
cd Inboxes/Python/FastAPI
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
Project/{Language}/{Framework}/src/
```

Each web framework exposes the same REST API and persists through its own ORM (Eloquent, SQLAlchemy, ActiveRecord, EF Core, Hibernate/JPA, Ecto, GORM), behind the same env-driven configuration.

Specialized projects swap the ORM for their own driver behind a factory:
- **DataPipeline** → `DataWarehouseAdapter` (duckdb/bigquery/postgresql)
- **SemanticSearch** → `VectorStoreAdapter` (chromadb/pgvector/pinecone)
- **EventProcessor** → `QueueAdapter` (redis/rabbitmq/kafka/sqs)
- **StreamVideo** → `VideoStorage`/`JobRepository`/`Transcoder`/`Analyzer` (AWS serverless, emulated via LocalStack)
- **APIGateway** → cache only (rate limiting), no DB
- **ChatAI** → `IChatProvider` abstraction over LLM providers, no DB/cache

The detailed architecture of each project (diagrams, adapters, data model, endpoints, logic) lives in the project's own `README.md`.

---

## 🧱 Architecture Principles

- Same domain behavior across languages and frameworks — the same set of apps implemented in PHP, Python, C#, Ruby, Java, Elixir and Go.
- Driver adapters behind a factory for specialized projects (warehouse, queue, vector store, LLM provider).
- Containers are runtime infrastructure, not business logic.

---

## 🛠️ Technologies

### ORM frameworks

| Language | Frameworks | ORM | Cache |
|----------|-----------|-----|-------|
| **PHP** | Laravel, Symfony | Eloquent / Doctrine | Redis / Local |
| **Python** | Flask, FastAPI, Django | SQLAlchemy / Django ORM | Redis / Local |
| **Ruby** | RubyOnRails | ActiveRecord | Redis / Local |
| **C#** | AspNetMinimalApi, Blazor | EF Core | Redis / Local |
| **Java** | Spring Boot | JPA/Hibernate | Redis / Local |
| **Elixir** | Phoenix | Ecto | Redis / Local |
| **Go** | Gin, Fiber | GORM | Redis / Local |

---

## 🗄️ Database & ⚡ Cache

Projects with persistence use an **ORM** in each framework, always behind the same env-driven configuration.

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

Each web framework includes `Dockerfile`, `docker-compose.yml` and `.dockerignore`. The repository keeps those standard OCI-compatible filenames, but the intended runtime is Podman. The compose files start the app, PostgreSQL (active), and Redis, with MySQL, SQL Server and MongoDB commented out for optional use. `CloudLocal` additionally includes local AWS, GCP and Azure service emulators. C# images are `.NET 10 Alpine` (`mcr.microsoft.com/dotnet/{sdk,aspnet}:10.0-alpine`).

All web apps expose the **host port `5006`** (container ports stay framework-native: `5000`, `8000`, `3000`, `4000`, `8080`). macOS reserves `5000` for AirPlay Receiver, so `5006` avoids the conflict and gives every project the same URL: `http://localhost:5006`.

Most implementations run with `podman compose up`. Notable exceptions:

| Project | Port | Command |
|---------|------|---------|
| **EventProcessor (SpringBoot)** | `5006` | `podman compose up` (adds Prometheus on `9090` and Grafana on `3001`) |
| **SemanticSearch (Flask)** | `5006` | `podman compose up` (adds a `chroma` service) |
| **StreamVideo (Python)** | `4566` (LocalStack) | `podman compose up --build pipeline` (emulated pipeline; no web port — runs the demo once) |

> **Why not rename to `Podmanfile`?** Podman can build standard `Dockerfile` files, and keeping `Dockerfile` + `docker-compose.yml` preserves compatibility with OCI tooling, IDEs and CI systems.

---

## 📐 Conventions

- **Separate files**: JS, CSS and HTML in independent files per framework.
- **Indentation**: 4 spaces for PHP, Python, C#; 2 spaces for Ruby; Go via `gofmt`.
- **ORM** used in every framework (Laravel, Symfony, Flask, FastAPI, Django, RubyOnRails, EF Core, JPA, Ecto, GORM). Specialized projects (warehouse, queue, vector store, LLM provider) use driver adapters behind a factory.
- **Cache**: two-level cache with Redis (default) and Local (fallback).
- **DB config**: individual variables `DB_DRIVER`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_FILE` (SQLite). In RubyOnRails, `database.yml` uses `url: <%= ENV["DATABASE_URL"] %>`.
- **Design patterns**: Adapter (Warehouse, Queue, Vector store, LLM provider), Factory, SOLID, clean code.

---

## 🧪 Tests

Each implementation includes unit tests using the standard framework for each language:

| Language | Framework | Command |
|----------|-----------|---------|
| PHP | PHPUnit | `vendor/bin/phpunit` |
| Python | pytest | `pytest` |
| C# | xUnit | `dotnet test` |
| Ruby | RubyOnRails | `rails test` |
| Java | JUnit 5 / Spring MockMvc | `mvn test` |
| Elixir | ExUnit | `mix test` |
| Go | Go testing (+ Ginkgo/Testify) | `go test ./...` |

> **Note:** database-backed projects require the `DB_DRIVER`, `DB_*` variables set for integration tests. Use `DB_DRIVER=sqlite` with `DB_FILE=test.db` for test environments.

### Run the whole portfolio

To test **everything in the repository** in one pass, use the test scripts. They discover every project with tests (**.NET**, **Java** and **Python**), run each suite inside an ephemeral Podman container (`--rm`) mounting the repo at `/app`, and print a PASS/FAIL summary. They use `CACHE_TYPE=local` and SQLite for DB-backed projects, so no services need to be started. Requires only **Podman** — no language toolchain needed on the host.

#### Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-tests.ps1          # all
powershell -ExecutionPolicy Bypass -File scripts/run-tests.ps1 -Tech python   # only Python
powershell -ExecutionPolicy Bypass -File scripts/run-tests.ps1 -Project APIGateway  # only APIGateway
```

#### Linux / macOS

```bash
chmod +x scripts/run-tests.sh
./scripts/run-tests.sh              # all
./scripts/run-tests.sh -t python    # only Python
./scripts/run-tests.sh -p APIGateway  # only APIGateway
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
| LocalStack socket errors | Check the `CloudLocal/docker-compose.yml` compose file because LocalStack may require a Docker-compatible socket when simulating some AWS services. |

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](./LICENSE) for details.