# CloudLocal

Local cloud service labs for AWS, GCP and Azure. This folder is for infrastructure emulators and provider-specific sandboxes, separate from the application portfolio projects.

## Structure

```text
CloudLocal/
├── docker-compose.yml
├── .env.example
├── aws/
│   └── localstack/
│       └── pipeline/
├── gcp/
│   ├── pubsub/
│   ├── firestore/
│   ├── bigtable/
│   └── storage/
├── azure/
│   ├── azurite/
│   └── cosmosdb/
└── shared/
    ├── scripts/
    └── healthchecks/
```

## Run

Start one provider:

```bash
podman compose --profile aws up
podman compose --profile gcp up
podman compose --profile azure up
```

Start all default local emulators:

```bash
podman compose --profile all up
```

Stop services:

```bash
podman compose --profile all down
```

## Services

| Provider | Local tool | Services | Ports |
|---|---|---|---|
| AWS | LocalStack | S3, DynamoDB, SQS, SNS, Lambda, CloudWatch | `4566` |
| GCP | Google Cloud SDK emulators | Pub/Sub, Firestore, Bigtable | `8085`, `8080`, `8086` |
| GCP | fake-gcs-server | Cloud Storage-compatible API | `4443` |
| Azure | Azurite | Blob, Queue, Table Storage | `10000`, `10001`, `10002` |
| Azure | Cosmos DB Emulator | Cosmos DB NoSQL | `8081`, `10250-10255` |

## Environment

Use `.env.example` as the common local variable map. Most SDKs detect emulator endpoints through environment variables such as `AWS_ENDPOINT_URL`, `PUBSUB_EMULATOR_HOST`, `FIRESTORE_EMULATOR_HOST`, `BIGTABLE_EMULATOR_HOST`, `STORAGE_EMULATOR_HOST` and `AZURE_STORAGE_CONNECTION_STRING`.

## AWS Pipeline

The existing LocalStack pipeline project now lives at:

```text
CloudLocal/aws/localstack/pipeline/Node.js/Web/Plain
```

Run the full app + worker + LocalStack + Redis + PostgreSQL stack from that folder:

```bash
cd CloudLocal/aws/localstack/pipeline/Node.js/Web/Plain
podman compose up
```

## Notes

- BigQuery does not have a complete official local emulator. Keep BigQuery adapters behind environment configuration or use test doubles for unit tests.
- GCP Storage uses `fake-gcs-server`, which is not an official Google emulator, but is useful for local Cloud Storage-compatible workflows.
- Cosmos DB Emulator can be heavier than Azurite. Run it explicitly with `--profile azure-cosmos` if you do not want the full `all` profile.
