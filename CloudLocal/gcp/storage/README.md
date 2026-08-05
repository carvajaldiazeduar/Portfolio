# GCP Storage-Compatible Emulator

This lab uses `fake-gcs-server` for local Cloud Storage-compatible development.

Run from `CloudLocal`:

```bash
podman compose --profile gcp up gcp-storage
```

Use:

```env
STORAGE_EMULATOR_HOST=http://localhost:4443
```
