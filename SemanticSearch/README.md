# SemanticSearch

Semantic search over documents: indexes documents (with embeddings), searches by vector similarity and manages collections. Embeddings and search use a configurable **vector store** with an optional cache.

## Architecture

Indexing + vector search. Vector persistence via a `VectorStoreAdapter` (interface + factory + per-driver adapters). On document upload an embedding is generated and inserted into the collection; search returns the `k` nearest neighbors with their distance.

```
POST /api/upload        ──► Service ──► VectorStoreAdapter ──► ChromaDB / PgVector / Pinecone
GET  /api/search?q=&k=  ──►   │
GET  /api/collections   ──►   └─► CacheAdapter (Redis / Local)  ── 300s TTL on search
DELETE /api/collections/:name
```

Search results are cached (default 300 s, key `search:<q>`); the cache is consulted before the vector store on read queries.

## Patterns

- **Adapter + Factory** for the vector store: `VectorStoreAdapter` (interface/ABC/base class) + `VectorStoreFactory` + `Adapters/{ChromaDB,PgVector,Pinecone}`.
- **Adapter + Factory** for cache (`CacheAdapter` + `CacheFactory` via `CACHE_TYPE`).
- ChromaDB is the default driver; implementations fall back to an **in-memory vector store** when Chroma is unreachable.

## Implementations

| Language | Frameworks |
|---|---|
| PHP | Laravel, Symfony |
| Python | Django, FastAPI, Flask |
| C# | AspNetMinimalApi, Blazor |
| Ruby | RubyOnRails |
| Java | SpringBoot |
| Elixir | Phoenix |

### Layout exceptions (do not "fix")

- **C# EXCEPTION**: does NOT use EF Core or an external `Storage/`. It defines abstract `VectorStoreAdapter`/`CacheAdapter` **inline in `Program.cs`** (Npgsql 7.0.0 + StackExchange.Redis 2.7.0). No DbContext.
- **Java EXCEPTION**: vector stores under `vectorstore/` (`VectorStoreAdapter` + `VectorStoreConfig` + `{ChromaDbVectorStore,PgVectorStore,PineconeStore,InMemoryVectorStore}`), cache via `CacheAdapter`/`CacheConfig`.
- **Elixir EXCEPTION**: vector drivers under `lib/<app>/vectorstore/` (`VectorStoreAdapter` behaviour + `VectorStoreFactory` + `{ChromaDB,PgVector,Pinecone,InMemory}`) and cache via the same `CacheAdapter` behaviour (`RedisCache` via Redix / `LocalCache` as a supervised Agent). No Repo.

## Data model

| Entity | Fields |
|---|---|
| `Document` | `id`, `text`, `embedding`, `metadata` |

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | UI |
| `POST` | `/api/upload` | Multipart file → indexes document → `{ "id": string, "status": "indexed" }` |
| `GET` | `/api/search?q=...&k=...` | Semantic search → `{ "results": [{ "document", "metadata", "distance" }] }` |
| `GET` | `/api/collections` | Lists collections |
| `DELETE` | `/api/collections/:name` | Deletes a collection |
| `GET` | `/openapi.json` | OpenAPI 3.0 spec |
| `GET` | `/swagger` | Swagger UI |

## Env vars

```
VECTOR_DRIVER=chromadb        # chromadb (default) | pinecone | pgvector
VECTOR_DIMENSION=1536
VECTOR_COLLECTION=documents
CHROMA_URL                    # per driver
PINECONE_API_KEY / PINECONE_ENV
PGVECTOR_CONNECTION
CACHE_TYPE=redis              # redis (default) | local
REDIS_HOST=localhost:6379
CACHE_TTL=300
```

## Containers / Ports

Compose adds a `chroma` service (in-network only, `chroma:8000`) alongside Redis. All web apps expose host port `5006` (container ports stay framework-native: `5000`, `8000`, `3000`, `4000`, C# `80`/`8000`, `elixir:1.17-alpine`). Run with `podman compose up`.

## Tests

- Python: pytest (`src/tests/`)
- PHP: PHPUnit
- C#: xUnit (`AspNetMinimalApi/src/tests/`)
- Ruby: `rails test`
- Java: JUnit 5 / Spring MockMvc (`mvn test`)
- Elixir: ExUnit (`mix test` from `Elixir/Phoenix/src/`)

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
