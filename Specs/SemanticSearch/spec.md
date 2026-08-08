# SemanticSearch — Spec

## Purpose
Semantic search over documents: indexes documents (with embeddings), searches by vector similarity and manages collections. Embeddings and search use a configurable vector store.

## Architecture
Indexing + vector search. Vector persistence via `VectorStoreAdapter` (interface + factory + per-driver adapters) and optional cache. On document upload an embedding is generated and inserted into the collection; search returns the `k` nearest with their distance.

## Implementations
- **PHP**: Cli + Web (Plain `src/`, Laravel, Symfony)
- **Python**: Cli + Web (Plain `app.py`, Flask, FastAPI, Django)
- **CSharp**: Web (AspNetMinimalApi, Blazor)
- **Node.js**: Cli + Web (Plain, Express, NextJS, React)
- **Ruby**: Cli + Web (RubyOnRails)

## Adapters
- **Vector store**: `VectorStoreAdapter` + `Adapters/{ChromaDB,PgVector,Pinecone}` + `VectorStoreFactory`
- **Cache**: `CacheAdapter` + `Adapters/{Redis,Local}` + `CacheFactory` (`CACHE_TYPE`, `REDIS_HOST`, `CACHE_TTL`)
- **C# EXCEPTION**: `SemanticSearch/CSharp` does NOT use EF Core or an external `Storage/`. It defines abstract `VectorStoreAdapter`/`CacheAdapter` **inline in `Program.cs`** with `Npgsql 7.0.0` + `StackExchange.Redis 2.7.0`. Do not add a DbContext there.
- **PHP Plain EXCEPTION**: keeps its cache classes under `src/Storage/` (CacheAdapter, CacheFactory, Adapters/{Local,Redis}.php) and its vector drivers under `src/Storage/Adapters/{ChromaDB,PgVector,Pinecone}.php`. Do not "fix" it.

## Env vars
- `VECTOR_DRIVER` (default `chromadb`) — `chromadb` | `pinecone` | `pgvector`
- `VECTOR_DIMENSION` (default `1536`), `VECTOR_COLLECTION` (default `documents`)
- `CHROMA_URL`, `PINECONE_API_KEY`, `PINECONE_ENV`, `PGVECTOR_CONNECTION` (per driver)
- `CACHE_TYPE` (default `redis`), `REDIS_HOST` (default `localhost:6379`), `CACHE_TTL` (default `300`)

## Endpoints
- `GET /` → UI
- `POST /api/upload` → multipart file → indexes document → `{ "id": string, "status": "indexed" }`
- `GET /api/search?q=...&k=...` → semantic search → `{ "results": [{ "document", "metadata", "distance" }] }`
- `GET /api/collections` → lists collections
- `DELETE /api/collections/:name` → deletes a collection
- `GET /openapi.json` → OpenAPI 3.0 spec of this API
- `GET /swagger` → Swagger UI (HTML, loads spec from CDN; FastAPI redirects to `/docs`)

## Tests
| Language | Framework | Where |
|---|---|---|
| Python | pytest | `Web/*/src/tests/` and `Cli/tests/` |
| Node | Jest | `Web/*/src/tests/` and `Cli/tests/` |
| PHP | assert | `Cli/tests/` via `php -d zend.assertions=1 -d assert.exception=1`; Plain Web via assert + `php -S 127.0.0.1:8000 index.php` |
| C# | xUnit | `Web/AspNetMinimalApi/src/tests/` (placeholder) |
| Ruby | Rails | `Web/RubyOnRails/src/` |

## Containers / Ports
Compose adds a `chroma` service alongside Redis. API per framework: Plain/Express/Flask `5000`, Laravel/Django/Rails `8000`, NextJS/React `3000`/`5173`, C# `80`/`8000`.
