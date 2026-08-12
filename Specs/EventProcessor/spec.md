# EventProcessor — Spec

## Purpose
Async event processor: receives events via API, publishes them to a queue and consumes/stores them via a worker. Decouples the producer (API) from the consumer (worker).

## Architecture
- **API** (`server.js`): receives `POST /events`, publishes to the queue and responds `202 Accepted`.
- **Worker** (`worker.js`): consumes events from the queue and processes them (persistence/log).
- **Queue**: `QueueAdapter` (interface + factory + per-driver adapters).

Node.js (Express) and Java (Spring Boot) implementations exist. No DB — only a queue.

## Implementations
- **Node.js**: Web (Express) + separate worker
- **Java**: Web (Spring Boot 3.3.4, Java 21) API + worker (worker profile)

## Adapters
- **Queue**: `QueueAdapter` + `QueueFactory` + `adapters/{RedisQueue,RabbitMQ,Kafka,SQS}.js`
- **Java queue**: `queue/` with `QueueAdapter` + `QueueConfig` (factory) + adapters `{InMemory,Redis,RabbitMq,Kafka,Sqs}`; worker via `JobWorker` + `JobRegistry`
- **Cache**: `CacheAdapter` + `Adapters/{Redis,Local}` (optional)

## Env vars
- `QUEUE_DRIVER` (default `redis`) — `redis` | `rabbitmq` | `kafka` | `sqs`
- `REDIS_HOST`, `REDIS_PORT`, `RABBITMQ_URL`, `KAFKA_BROKERS`, `AWS_*` (per driver)
- `CACHE_TYPE` (default `redis`), `REDIS_HOST` (default `localhost:6379`)
- `WORKER_METRICS_PORT` (default `3001`) — port where the worker exposes `/metrics`

## Endpoints
- `POST /events` → body `{ "type": string, "payload": object }` → `202 Accepted` + `{ "status": "queued" }`
- `GET /health` → service status
- `GET /openapi.json` → OpenAPI 3.0 spec of this API
- `GET /swagger` → Swagger UI (HTML, loads spec from CDN)
- `GET /metrics` → Prometheus metrics (API on `:3000`, worker on `WORKER_METRICS_PORT`)

## Worker
- Continuously processes events from the queue
- Marks events as processed or retries them on failure

## Observability
- **Prometheus** (`:9090`) scrapes the API (`/metrics` on `:3000`) and the worker (`/metrics` on `WORKER_METRICS_PORT`)
- **Grafana** (`:3001` UI, default user `admin` / password `admin`) with a provisioned datasource and the `EventProcessor` dashboard
- Metrics: `http_requests_total`, `http_request_duration_seconds`, `jobs_published_total`, `jobs_processed_total`, `jobs_processing_duration_seconds` + default Node.js metrics
- Config lives under `monitoring/prometheus/` and `monitoring/grafana/`

## Tests
| Language | Framework | Where |
|---|---|---|
| Node.js | Jest | `src/tests/` |
| Java | JUnit + Spring MockMvc (Maven) | `Java/Web/SpringBoot` via `mvn test` |

## Containers / Ports
Compose: `event-processor-api` on `3000:3000` + `event-processor-worker` (separate service) + Redis on `6379:6379` + Prometheus on `9090:9090` + Grafana on `3001:3000`.
