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

- **Adapter + Factory** for the warehouse: `DataWarehouseAdapter` (ABC/base class) + `WarehouseConfig`/`warehouse_factory.py` + `Adapters/{duckdb,bigquery,postgresql}`.
- **Adapter + Factory** for cache (`CacheAdapter` + `CacheFactory` via `CACHE_TYPE`).
- DuckDB is the default driver (zero-config local warehouse).

## Implementations

| Language | Web |
|---|---|
| Python | `Web/Plain` (`src/`) |
| Java | `Web/SpringBoot` |

- **Python**: `storage/warehouse_adapter.py` + `warehouse_factory.py` + `adapters/{duckdb,bigquery,postgresql}.py`; cache via `cache_adapter.py` + `adapters/{redis,local}.py` (`create_cache`).
- **Java**: `DataWarehouseAdapter` + `WarehouseConfig` + `{DuckDb,BigQuery,Postgresql}Warehouse`; cache via `CacheAdapter`/`CacheConfig` (`LocalCache`/`RedisCache`).

## Data model

| Entity | Fields |
|---|---|
| `SourceRecord` | `source`, `data`, `processed` |

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | UI |
| `GET` | `/api/health` | Service status |
| `GET` | `/api/pipelines` | Lists defined pipelines |
| `POST` | `/api/pipelines/<name>/run` | Runs a pipeline → `{ "status": "success", "rows_processed": n }` |
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

Compose lives in `DataPipeline/Python/Web/Plain`. Port per framework.

## Tests

- Python: pytest (`src/tests/`, run from `src/`)
- Java: JUnit + Spring MockMvc (`mvn test`)

Full contract: [`Specs/DataPipeline/spec.md`](../Specs/DataPipeline/spec.md)
