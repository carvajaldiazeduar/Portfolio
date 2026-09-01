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

- **Adapter + Factory** for the queue: `queue/` with `InMemory`/`Redis`/`RabbitMq`/`Kafka`/`Sqs` + `JobWorker` + `JobRegistry` (Java).
- **Producer-consumer** decoupling via the queue.
- **Observability**: Prometheus + Grafana for metrics.

## Implementations

| Language | Frameworks |
|---|---|
| Java | SpringBoot API + worker (worker profile) |

## Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/events` | `{ "type": string, "payload": object }` → `202 Accepted` + `{ "status": "queued" }` |
| `GET` | `/health` | Service status |
| `GET` | `/metrics` | Prometheus metrics (API on `:5000`, worker on `WORKER_METRICS_PORT`) |
| `GET` | `/openapi.json` | OpenAPI 3.0 spec |
| `GET` | `/swagger` | Swagger UI |

## Worker

- Continuously processes events from the queue.
- Marks events as processed or retries them on failure.

## Observability

- **Prometheus** (`:9090`) scrapes the API (`/metrics` on container port `5000`) and the worker (`/metrics` on `WORKER_METRICS_PORT`).
- **Grafana** (`:3001` UI, default `admin`/`admin`) with a provisioned datasource and the `EventProcessor` dashboard.
- Metrics: `http_requests_total`, `http_request_duration_seconds`, `jobs_published_total`, `jobs_processed_total`, `jobs_processing_duration_seconds`.
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

Compose: `event-processor-api` on `5006:5000` + `event-processor-worker` (separate service) + Redis on `6379:6379` + Prometheus on `9090:9090` + Grafana on `3001:3000`. Run with Podman and open **`http://localhost:5006`**:

```bash
cd EventProcessor/Java/SpringBoot
podman compose up
```

## Tests

- Java: JUnit + Spring MockMvc (`mvn test`)

Run the suite with no host toolchain (Podman only), from the implementation folder:

```bash
# Java
podman run --rm -v "$(pwd):/app" -w /app -e CACHE_TYPE=local maven:3.9-eclipse-temurin-21 mvn test
```
