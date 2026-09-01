# Azure Cosmos DB Emulator

Run from `CloudLocal`:

```bash
podman compose --profile azure-cosmos up azure-cosmosdb
```

Use:

```env
AZURE_COSMOS_ENDPOINT=https://localhost:8081
AZURE_COSMOS_KEY=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==
```

The emulator uses a development key and is not intended for production workloads.
