# GCP Local Services

GCP local development uses official Google Cloud SDK emulators where available, plus a Cloud Storage-compatible emulator for storage workflows.

## Services

| Service | Tool | Port | Environment variable |
|---|---|---|---|
| Pub/Sub | Google Cloud SDK emulator | `8085` | `PUBSUB_EMULATOR_HOST=localhost:8085` |
| Firestore | Google Cloud SDK emulator | `8080` | `FIRESTORE_EMULATOR_HOST=localhost:8080` |
| Bigtable | Google Cloud SDK emulator | `8086` | `BIGTABLE_EMULATOR_HOST=localhost:8086` |
| Cloud Storage | fake-gcs-server | `4443` | `STORAGE_EMULATOR_HOST=http://localhost:4443` |

## Run

From `CloudLocal`:

```bash
podman compose --profile gcp up
```

## BigQuery

BigQuery does not have a complete official local emulator. Keep it behind adapter configuration and use local test doubles, DuckDB, or mocked clients for tests that should not call real Google Cloud.
