<?php

function listCollections(): array {
    $driver = getenv('VECTOR_DRIVER') ?: 'chromadb';
    $adapter = match ($driver) {
        'pinecone' => new PineconeAdapter(),
        'pgvector' => new PgVectorAdapter(),
        default => new ChromaDBAdapter(),
    };
    $adapter->connect();
    return $adapter->listCollections();
}

function search(string $query): array {
    $driver = getenv('VECTOR_DRIVER') ?: 'chromadb';
    $adapter = match ($driver) {
        'pinecone' => new PineconeAdapter(),
        'pgvector' => new PgVectorAdapter(),
        default => new ChromaDBAdapter(),
    };
    $adapter->connect();
    $dimension = (int)(getenv('VECTOR_DIMENSION') ?: 1536);
    return $adapter->search(array_fill(0, $dimension, 0.0), 5);
}

function deleteCollection(string $name): void {
    $driver = getenv('VECTOR_DRIVER') ?: 'chromadb';
    $adapter = match ($driver) {
        'pinecone' => new PineconeAdapter(),
        'pgvector' => new PgVectorAdapter(),
        default => new ChromaDBAdapter(),
    };
    $adapter->connect();
    $adapter->deleteCollection($name);
}

echo "Semantic Search CLI\n";
echo "1. List collections\n";
echo "2. Search documents\n";
echo "3. Delete collection\n";
echo "4. Exit\n";
echo "Choose an option: ";
$choice = trim(fgets(STDIN));

switch ($choice) {
    case '1':
        $collections = listCollections();
        foreach ($collections as $c) echo "  - $c\n";
        break;
    case '2':
        echo "Search query: ";
        $q = trim(fgets(STDIN));
        $results = search($q);
        foreach ($results as $r) echo "  [{$r['distance']}] " . substr($r['document'], 0, 100) . "\n";
        break;
    case '3':
        echo "Collection name: ";
        $name = trim(fgets(STDIN));
        deleteCollection($name);
        echo "Collection '$name' deleted\n";
        break;
    case '4':
        echo "Goodbye!\n";
        break;
}