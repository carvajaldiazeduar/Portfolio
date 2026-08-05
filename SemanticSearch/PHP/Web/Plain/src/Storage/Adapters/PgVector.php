<?php
require_once __DIR__ . '/../VectorAdapter.php';

class PgVector implements VectorStoreAdapter {
    private ?PDO $pdo = null;

    public function connect(): void {
        if ($this->pdo !== null && $this->pdo->query("SELECT 1")->fetch()) return;
        $host = getenv('DB_HOST') ?: 'db';
        $port = getenv('DB_PORT') ?: '5432';
        $name = getenv('DB_NAME') ?: 'semantic_search';
        $user = getenv('DB_USER') ?: 'postgres';
        $pass = getenv('DB_PASSWORD') ?: 'postgres';
        $this->pdo = new PDO("pgsql:host=$host;port=$port;dbname=$name", $user, $pass);
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->pdo->exec("CREATE EXTENSION IF NOT EXISTS vector");
    }

    public function addDocuments(array $documents, array $embeddings, array $metadata): void {
        $this->connect();
        $collectionName = getenv('VECTOR_COLLECTION') ?: 'documents';
        $table = "vector_" . str_replace('-', '_', $collectionName);
        $this->pdo->exec("CREATE TABLE IF NOT EXISTS $table (id SERIAL PRIMARY KEY, document TEXT, embedding vector, metadata JSONB)");
        $stmt = $this->pdo->prepare("INSERT INTO $table (document, embedding, metadata) VALUES (?, ?, ?)");
        foreach ($documents as $i => $doc) {
            $stmt->execute([$doc, $embeddings[$i], json_encode($metadata[$i])]);
        }
    }

    public function search(array $queryEmbedding, int $nResults = 5): array {
        $this->connect();
        $collectionName = getenv('VECTOR_COLLECTION') ?: 'documents';
        $table = "vector_" . str_replace('-', '_', $collectionName);
        $stmt = $this->pdo->prepare("SELECT document, metadata, embedding <=> ?::vector AS distance FROM $table ORDER BY embedding <=> ?::vector LIMIT ?");
        $jsonEmbedding = json_encode($queryEmbedding);
        $stmt->execute([$jsonEmbedding, $jsonEmbedding, $nResults]);
        return array_map(fn($row) => [
            'document' => $row['document'],
            'metadata' => json_decode($row['metadata'], true),
            'distance' => $row['distance'],
        ], $stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function deleteCollection(string $collectionName): void {
        $table = "vector_" . str_replace('-', '_', $collectionName);
        $this->pdo->exec("DROP TABLE IF EXISTS $table");
    }

    public function listCollections(): array {
        $this->connect();
        $stmt = $this->pdo->query("SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'vector_%'");
        return array_map(fn($row) => $row['table_name'], $stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function close(): void {
        $this->pdo = null;
    }
}