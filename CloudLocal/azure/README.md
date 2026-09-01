# Azure Local Services

Azure local development uses Azurite for Storage and the Cosmos DB Emulator for NoSQL database workflows.

## Services

| Service | Tool | Port |
|---|---|---|
| Blob Storage | Azurite | `10000` |
| Queue Storage | Azurite | `10001` |
| Table Storage | Azurite | `10002` |
| Cosmos DB NoSQL | Azure Cosmos DB Emulator | `8081`, `10250-10255` |

## Run

From `CloudLocal`, start Azurite:

```bash
podman compose --profile azure up
```

Start Cosmos DB Emulator explicitly:

```bash
podman compose --profile azure-cosmos up
```

## Environment

```env
AZURE_STORAGE_CONNECTION_STRING=UseDevelopmentStorage=true
AZURE_COSMOS_ENDPOINT=https://localhost:8081
```
