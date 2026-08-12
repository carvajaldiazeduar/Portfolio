# DataPipeline — Spec

## Purpose
Configurable ETL data pipeline: ingest data from sources (CSV/JSON), transform and load it into a data warehouse. Exposes runnable pipelines via API and offers source queries.

## Architecture
Lightweight ETL pipeline in Python. Warehouse persistence via `DataWarehouseAdapter` (interface + factory + per-driver adapters) and optional cache. Pipelines are defined by name and run synchronously.

Only a **Python** implementation exists.

## Implementations
- **Python**: Web (Plain, Flask)
- **Java**: Web (Spring Boot 3.3.4, Java 21; warehouse adapters — DuckDB default — + cache)

## Adapters
- **Warehouse**: `warehouse_adapter.py` (ABC) + `warehouse_factory.py` + `adapters/{duckdb,bigquery,postgresql}.py`
- **Cache**: `cache_adapter.py` + `adapters/{redis,local}.py` + `cache_factory.py` (`create_cache`)

## Env vars
- `WAREHOUSE_DRIVER` (default `duckdb`) — `duckdb` | `bigquery` | `postgresql`
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` (for postgresql warehouse)
- `GOOGLE_APPLICATION_CREDENTIALS` / `GCP_PROJECT` (for bigquery)
- `CACHE_TYPE` (default `redis`), `REDIS_HOST` (default `localhost:6379`), `CACHE_TTL` (default `300`)

## Endpoints
- `GET /` → UI
- `GET /api/health` → service status
- `GET /api/pipelines` → lists defined pipelines
- `POST /api/pipelines/<name>/run` → runs a pipeline → `{ "status": "success", "rows_processed": n }`
- `GET /api/sources` → lists available data sources
- `GET /openapi.json` → OpenAPI 3.0 spec of this API
- `GET /swagger` → Swagger UI (HTML, loads spec from CDN)

## Tests
| Language | Framework | Where |
|---|---|---|
| Python | pytest | `src/tests/` (from `src/`) |
| Java | JUnit + Spring MockMvc (Maven) | `Java/Web/SpringBoot` via `mvn test` |

## Containers / Ports
Compose in `DataPipeline/Python/Web/Plain`. Port per framework.
