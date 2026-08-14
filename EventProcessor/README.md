# EventProcessor

Async event processor: receives events via API, publishes them to a queue and consumes/stores them via a worker. Decouples the **producer** (API) from the **consumer** (worker). **No DB** — only a queue.

## Architecture

Two processes share a queue:

```
POST /events ──► API (producer) ──► QueueAdapter ──► Redis / RabbitMQ / Kafka / SQS
                                                      │
                     Worker (consumer) ◄──────────────┘
                          │
                    process / persist / retry
```

- **API**: receives `POST /events`, publishes to the queue and responds `202 Accepted` immediately.
- **Worker**: continuously consumes events, processes them and marks them as processed or retries them on failure.
- **Queue**: `QueueAdapter` (interface + factory + per-driver adapters), selected via `QUEUE_DRIVER`.

## Patterns

- **Adapter + Factory** for the queue: `QueueAdapter` + `QueueFactory` + `Adapters/{RedisQueue,RabbitMQ,Kafka,SQS}` (Node) or `queue/` with `InMemory`/`Redis`/`RabbitMq`/`Kafka`/`Sqs` + `JobWorker` + `JobRegistry` (Java).
- **Producer-consumer** decoupling via the queue.
- **Observability**: Prometheus + Grafana for metrics.

## Implementations

| Language | Web |
|---|---|
| Node.js | `Web/Plain` (Express) + separate worker |
| Java | `Web/SpringBoot` API + worker (worker profile) |

## Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/events` | `{ "type": string, "payload": object }` → `202 Accepted` + `{ "status": "queued" }` |
| `GET` | `/health` | Service status |
| `GET` | `/metrics` | Prometheus metrics (API on `:3000`, worker on `WORKER_METRICS_PORT`) |
| `GET` | `/openapi.json` | OpenAPI 3.0 spec |
| `GET` | `/swagger` | Swagger UI |

## Worker

- Continuously processes events from the queue.
- Marks events as processed or retries them on failure.

## Observability

- **Prometheus** (`:9090`) scrapes the API (`/metrics` on `:3000`) and the worker (`/metrics` on `WORKER_METRICS_PORT`).
- **Grafana** (`:3001` UI, default `admin`/`admin`) with a provisioned datasource and the `EventProcessor` dashboard.
- Metrics: `http_requests_total`, `http_request_duration_seconds`, `jobs_published_total`, `jobs_processed_total`, `jobs_processing_duration_seconds` + default Node.js metrics.
- Config lives under `monitoring/prometheus/` and `monitoring/grafana/`.

## Env vars

```
QUEUE_DRIVER=redis             # redis (default) | rabbitmq | kafka | sqs
REDIS_HOST / REDIS_PORT        # for redis
RABBITMQ_URL                   # for rabbitmq
KAFKA_BROKERS                  # for kafka
AWS_*                          # for sqs
CACHE_TYPE=redis               # redis (default) | local
WORKER_METRICS_PORT=3001       # port where the worker exposes /metrics
```

## Containers / Ports

Compose: `event-processor-api` on `3000:3000` + `event-processor-worker` (separate service) + Redis on `6379:6379` + Prometheus on `9090:9090` + Grafana on `3001:3000`. Run with `podman compose up`.

## Tests

- Node.js: Jest (`src/tests/`)
- Java: JUnit + Spring MockMvc (`mvn test`)

Full contract: [`Specs/EventProcessor/spec.md`](../Specs/EventProcessor/spec.md)
