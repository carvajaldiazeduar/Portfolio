<?php
require_once __DIR__ . '/../VectorAdapter.php';

class Pinecone implements VectorStoreAdapter {
    private ?object $index = null;

    public function connect(): void {
        if ($this->index !== null) return;
        $pinecone = new \Pinecone\Pinecone(getenv('PINECONE_API_KEY') ?: '');
        $indexName = getenv('PINECONE_INDEX') ?: 'documents';
        $this->index = $pinecone->index($indexName);
    }

    public function addDocuments(array $documents, array $embeddings, array $metadata): void {
        $this->connect();
        $vectors = [];
        foreach ($documents as $i => $doc) {
            $vectors[] = [
                'id' => "doc_$i",
                'values' => $embeddings[$i],
                'metadata' => array_merge($metadata[$i], ['text' => $doc]),
            ];
        }
        $this->index->upsert($vectors);
    }

    public function search(array $queryEmbedding, int $nResults = 5): array {
        $this->connect();
        $results = $this->index->query($queryEmbedding, $nResults, true);
        return array_map(fn($match) => [
            'document' => $match['metadata']['text'] ?? '',
            'metadata' => array_diff_key($match['metadata'], ['text' => true]),
            'distance' => $match['score'] ?? null,
        ], $results['matches'] ?? []);
    }

    public function deleteCollection(string $collectionName): void {}

    public function listCollections(): array {
        try {
            $pinecone = new \Pinecone\Pinecone(getenv('PINECONE_API_KEY') ?: '');
            return array_map(fn($i) => $i->name, $pinecone->listIndexes());
        } catch (Exception $e) {
            return [];
        }
    }

    public function close(): void {
        $this->index = null;
    }
}