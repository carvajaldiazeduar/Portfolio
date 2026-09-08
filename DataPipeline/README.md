# DataPipeline

Configurable ETL data pipeline: ingest data from sources (CSV/JSON), transform and load it into a data warehouse. Exposes runnable pipelines via an API and offers source queries.

## Architecture

Lightweight ETL pipeline. Warehouse persistence via a `DataWarehouseAdapter` (interface + factory + per-driver adapters) and optional cache. Pipelines are defined by name and run synchronously.

```
POST /api/pipelines/<name>/run ──► PipelineService ──► DataWarehouseAdapter ──► duckdb / bigquery / postgresql
GET  /api/pipelines ──► lists defined pipelines
GET  /api/sources   ──► lists available data sources
```

The **transform** step is deterministic and pipeline-specific; the **load** step writes through the warehouse adapter, so the warehouse engine is swappable without touching pipeline logic.

## Patterns

- **Adapter + Factory** for the warehouse: `DataWarehouseAdapter` + `WarehouseConfig` + `{DuckDb,BigQuery,Postgresql}Warehouse`.
- **Adapter + Factory** for cache (`CacheAdapter`/`CacheConfig` via `LocalCache`/`RedisCache`).
- DuckDB is the default driver (zero-config local warehouse).

## Implementations

| Language | Frameworks |
|---|---|
| Java | SpringBoot |

## Data model

| Entity | Fields |
|---|---|
| `SourceRecord` | `source`, `data`, `processed` |

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | UI (with a live chart of recent runs — Chart.js via CDN) |
| `GET` | `/api/health` | Service status |
| `GET` | `/api/pipelines` | Lists defined pipelines |
| `POST` | `/api/pipelines/<name>/run` | Runs a pipeline → `{ "status": "success", "rows_processed": n }` |
| `GET` | `/api/runs` | Recent run history (in-memory, last 50) → powers the UI chart |
| `GET` | `/api/sources` | Lists available data sources |
| `GET` | `/openapi.json` | OpenAPI 3.0 spec |
| `GET` | `/swagger` | Swagger UI |

## Env vars

```
WAREHOUSE_DRIVER=duckdb        # duckdb (default) | bigquery | postgresql
DB_HOST / DB_PORT / DB_NAME / DB_USER / DB_PASSWORD   # for postgresql warehouse
GOOGLE_APPLICATION_CREDENTIALS / GCP_PROJECT          # for bigquery
CACHE_TYPE=redis               # redis (default) | local
REDIS_HOST=localhost:6379
CACHE_TTL=300
```

## Containers / Ports

Compose lives in `DataPipeline/Java/SpringBoot` (`docker-compose.yml`, `Dockerfile`): Spring Boot API on `5006`, Redis on `6379`. DuckDB warehouse is a file-based local engine (no extra service).

Run with Podman and open **`http://localhost:5006`**:

```bash
cd DataPipeline/Java/SpringBoot
podman compose up
```

## Tests

- Java: JUnit + Spring MockMvc (`mvn test`)

Run the suite with no host toolchain (Podman only), from the implementation folder:

```bash
# Java
podman run --rm -v "$(pwd):/app" -w /app -e CACHE_TYPE=local maven:3.9-eclipse-temurin-21 mvn test
```
