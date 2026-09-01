# Azurite

Azurite emulates Azure Blob, Queue and Table Storage.

Run from `CloudLocal`:

```bash
podman compose --profile azure up azure-azurite
```

Default ports:

- Blob: `10000`
- Queue: `10001`
- Table: `10002`

Use:

```env
AZURE_STORAGE_CONNECTION_STRING=UseDevelopmentStorage=true
```
