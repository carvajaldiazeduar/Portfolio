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

| Language | Cli | Web |
|---|---|---|
| PHP | `Cli` | `Web/{Plain,Laravel,Symfony}` |
| Python | `Cli` | `Web/{Plain,Flask,FastAPI,Django}` |
| C# | — | `Web/{AspNetMinimalApi,Blazor}` |
| Node.js | `Cli` | `Web/{Plain,Express,NextJS,React}` |
| Ruby | `Cli` | `Web/RubyOnRails` |
| Java | `Cli` | `Web/SpringBoot` |
| Elixir | `Cli` (mix escript) | `Web/Phoenix` |

### Layout exceptions (do not "fix")

- **C# EXCEPTION**: does NOT use EF Core or an external `Storage/`. It defines abstract `VectorStoreAdapter`/`CacheAdapter` **inline in `Program.cs`** (Npgsql 7.0.0 + StackExchange.Redis 2.7.0). No DbContext.
- **PHP Plain EXCEPTION**: keeps cache classes under `src/Storage/` (CacheAdapter, CacheFactory, Adapters/{Local,Redis}.php) and vector drivers under `src/Storage/Adapters/{ChromaDB,PgVector,Pinecone}.php`.
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

Compose adds a `chroma` service alongside Redis. API per framework: Plain/Express/Flask/Spring Boot `5000`, Laravel/Django/Rails `8000`, NextJS/React `3000`/`5173`, C# `80`/`8000`, Phoenix `4000` (`elixir:1.17-alpine`). Run with `podman compose up`.

## Tests

- Python: pytest (`Cli/tests/`, `Web/*/src/tests/`)
- Node.js: Jest (`Cli/tests/`, `Web/*/src/tests/`)
- PHP: assert (Cli, Plain Web with `php -S 127.0.0.1:8000`)
- C#: xUnit (`Web/AspNetMinimalApi/src/tests/`)
- Ruby: `rails test`
- Java: JUnit 5 / Spring MockMvc (`mvn test`)
- Elixir: ExUnit (`mix test` from `Cli/` or `Web/Phoenix/src/`)

Full contract: [`Specs/SemanticSearch/spec.md`](../Specs/SemanticSearch/spec.md)
