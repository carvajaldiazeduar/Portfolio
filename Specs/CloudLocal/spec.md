# CloudLocal — Spec

## Purpose
Cloud emulator infrastructure for local development: emulates AWS, GCP and Azure services with Docker (Podman) and per-provider profiles. It is not an app; it is the emulator/environment apps use for local testing.

## Architecture
Root compose in `CloudLocal/` with per-provider profiles. Each provider has its isolated setup; shared helpers live in `shared/`.

## Implementations
- **AWS** (`aws/localstack`): LocalStack (S3, DynamoDB, SQS, etc.)
- **GCP** (`gcp/`): Google Cloud SDK emulators (Firestore, Pub/Sub, Bigtable) + `fake-gcs-server` for Storage
- **Azure** (`azure/`): Azurite (Blob/Queue/Table) + Cosmos DB Emulator

## Env vars
- Config in `CloudLocal/.env.example` (AWS/GCP/Azure endpoints)

## Commands (from `CloudLocal/`)
- `podman compose --profile aws up` — AWS only
- `podman compose --profile gcp up` — GCP only
- `podman compose --profile azure up` — Azure only (Azurite)
- `podman compose --profile azure-cosmos up` — Cosmos DB Emulator
- `podman compose --profile all up` — all

## Ports
AWS `4566` (LocalStack), GCP emulators `8080`/`8081`/`8085`/`8086`, fake Storage `4443`, Azurite `10000`/`10001`/`10002`, Cosmos `8081`, plus `5432` (PostgreSQL) and `6379` (Redis).

## Structure
- `aws/localstack/pipeline` — may require special review (LocalStack may depend on a Docker-compatible socket for some AWS workflows)
- `shared/healthchecks`, `shared/scripts`, `shared/README.md` — shared helpers
- `{aws,gcp,azure}/README.md` — per-provider documentation

## Notes
Keep per-provider setup inside `CloudLocal/{aws,gcp,azure}` and shared helpers in `CloudLocal/shared`.
