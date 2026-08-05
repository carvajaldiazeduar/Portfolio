<?php
require_once __DIR__ . '/../VectorAdapter.php';

class ChromaDB implements VectorStoreAdapter {
    private ?object $client = null;
    private array $collections = [];

    public function connect(): void {
        if ($this->client !== null) return;
        try {
            $this->client = new \Chroma\Client(
                getenv('CHROMA_HOST') ?: 'localhost',
                (int)(getenv('CHROMA_PORT') ?: '8000')
            );
        } catch (Exception $e) {
            $this->client = new \Chroma\Client();
        }
    }

    public function addDocuments(array $documents, array $embeddings, array $metadata): void {
        $this->connect();
        $collectionName = getenv('VECTOR_COLLECTION') ?: 'documents';
        if (!isset($this->collections[$collectionName])) {
            $this->collections[$collectionName] = $this->client->getOrCreateCollection($collectionName);
        }
        $collection = $this->collections[$collectionName];
        $ids = array_map(fn($i) => "doc_$i", range(0, count($documents) - 1));
        $collection->add($documents, $embeddings, $metadata, $ids);
    }

    public function search(array $queryEmbedding, int $nResults = 5): array {
        $this->connect();
        $collectionName = getenv('VECTOR_COLLECTION') ?: 'documents';
        if (!isset($this->collections[$collectionName])) return [];
        $collection = $this->collections[$collectionName];
        $results = $collection->query([$queryEmbedding], $nResults);
        return array_map(fn($i) => [
            'document' => $results['documents'][0][$i] ?? '',
            'metadata' => $results['metadatas'][0][$i] ?? [],
            'distance' => $results['distances'][0][$i] ?? null,
        ], range(0, min($nResults, count($results['documents'][0] ?? [])) - 1));
    }

    public function deleteCollection(string $collectionName): void {
        unset($this->collections[$collectionName]);
        try { $this->client->deleteCollection($collectionName); } catch {}
    }

    public function listCollections(): array {
        $this->connect();
        return array_map(fn($c) => $c->name, $this->client->listCollections());
    }

    public function close(): void {
        $this->collections = [];
        $this->client = null;
    }
}