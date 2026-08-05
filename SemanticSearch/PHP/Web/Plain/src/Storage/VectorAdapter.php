<?php
interface VectorStoreAdapter {
    public function connect(): void;
    public function addDocuments(array $documents, array $embeddings, array $metadata): void;
    public function search(array $queryEmbedding, int $nResults = 5): array;
    public function deleteCollection(string $collectionName): void;
    public function listCollections(): array;
    public function close(): void;
}