<?php
require_once __DIR__ . '/VectorAdapter.php';
require_once __DIR__ . '/Adapters/ChromaDB.php';
require_once __DIR__ . '/Adapters/Pinecone.php';
require_once __DIR__ . '/Adapters/PgVector.php';

class VectorFactory {
    public static function create(): VectorStoreAdapter {
        $driver = getenv('VECTOR_DRIVER') ?: 'chromadb';
        return match ($driver) {
            'pinecone' => new Pinecone(),
            'pgvector' => new PgVector(),
            default => new ChromaDB(),
        };
    }
}