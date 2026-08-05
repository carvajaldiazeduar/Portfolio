# GCP Firestore Emulator

Run from `CloudLocal`:

```bash
podman compose --profile gcp up gcp-firestore
```

Use:

```env
FIRESTORE_EMULATOR_HOST=localhost:8080
GCP_PROJECT_ID=local-project
```
