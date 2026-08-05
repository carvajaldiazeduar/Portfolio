# GCP Pub/Sub Emulator

Run from `CloudLocal`:

```bash
podman compose --profile gcp up gcp-pubsub
```

Use:

```env
PUBSUB_EMULATOR_HOST=localhost:8085
GCP_PROJECT_ID=local-project
```
