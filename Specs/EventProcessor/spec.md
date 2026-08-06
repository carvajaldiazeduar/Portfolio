# EventProcessor — Spec

## Purpose
Async event processor: receives events via API, publishes them to a queue and consumes/stores them via a worker. Decouples the producer (API) from the consumer (worker).

## Architecture
- **API** (`server.js`): receives `POST /events`, publishes to the queue and responds `202 Accepted`.
- **Worker** (`worker.js`): consumes events from the queue and processes them (persistence/log).
- **Queue**: `QueueAdapter` (interface + factory + per-driver adapters).

Only a **Node.js** implementation exists. No DB — only a queue.

## Implementations
- **Node.js**: Web (Express) + separate worker

## Adapters
- **Queue**: `QueueAdapter` + `QueueFactory` + `adapters/{RedisQueue,RabbitMQ,Kafka,SQS}.js`
- **Cache**: `CacheAdapter` + `Adapters/{Redis,Local}` (optional)

## Env vars
- `QUEUE_DRIVER` (default `redis`) — `redis` | `rabbitmq` | `kafka` | `sqs`
- `REDIS_HOST`, `REDIS_PORT`, `RABBITMQ_URL`, `KAFKA_BROKERS`, `AWS_*` (per driver)
- `CACHE_TYPE` (default `redis`), `REDIS_HOST` (default `localhost:6379`)

## Endpoints
- `POST /events` → body `{ "type": string, "payload": object }` → `202 Accepted` + `{ "status": "queued" }`
- `GET /health` → service status
- `GET /openapi.json` → OpenAPI 3.0 spec of this API
- `GET /swagger` → Swagger UI (HTML, loads spec from CDN)

## Worker
- Continuously processes events from the queue
- Marks events as processed or retries them on failure

## Tests
| Language | Framework | Where |
|---|---|---|
| Node.js | Jest | `src/tests/` |

## Containers / Ports
Compose: `event-processor-api` on `3000:3000` + `event-processor-worker` (separate service) + Redis on `6379:6379`.
