<?php
require_once __DIR__ . '/Storage/VectorFactory.php';
require_once __DIR__ . '/Storage/CacheFactory.php';
require_once __DIR__ . '/Storage/CacheAdapter.php';
require_once __DIR__ . '/Storage/Adapters/Local.php';
require_once __DIR__ . '/Storage/Adapters/Redis.php';

$vectorStore = VectorFactory::create();
$vectorStore->connect();
$cache = CacheFactory::create();

$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

header('Content-Type: application/json');

if ($path === '/' || $path === '/index.php') {
    header('Content-Type: text/html');
    echo file_get_contents(__DIR__ . '/template.html');
    exit;
}

if ($path === '/api/upload' && $method === 'POST') {
    $file = $_FILES['file'] ?? null;
    if (!$file || $file['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode(['error' => 'No file provided']);
        exit;
    }
    $content = file_get_contents($file['tmp_name']);
    $metadata = ['filename' => $file['name'], 'source' => 'upload'];
    $dimension = (int)(getenv('VECTOR_DIMENSION') ?: 1536);
    $vectorStore->addDocuments([$content], [array_fill(0, $dimension, 0.0)], [$metadata]);
    $cache->delete('search:results');
    echo json_encode(['message' => 'Document indexed', 'filename' => $file['name']]);
    exit;
}

if ($path === '/api/search' && $method === 'GET') {
    $q = $_GET['q'] ?? '';
    if (!$q) {
        http_response_code(400);
        echo json_encode(['error' => "Query parameter 'q' is required"]);
        exit;
    }
    $cached = $cache->get("search:$q");
    if ($cached !== null) {
        echo $cached;
        exit;
    }
    $dimension = (int)(getenv('VECTOR_DIMENSION') ?: 1536);
    $results = $vectorStore->search(array_fill(0, $dimension, 0.0), 5);
    $cache->set("search:$q", json_encode($results), 300);
    echo json_encode(['query' => $q, 'results' => $results]);
    exit;
}

if ($path === '/api/collections' && $method === 'GET') {
    $collections = $vectorStore->listCollections();
    echo json_encode(['collections' => $collections]);
    exit;
}

if (preg_match('#^/api/collections/([^/]+)$#', $path, $matches) && $method === 'DELETE') {
    $vectorStore->deleteCollection($matches[1]);
    $cache->delete('search:results');
    echo json_encode(['message' => "Collection '{$matches[1]}' deleted"]);
    exit;
}

http_response_code(404);
echo json_encode(['error' => 'Not found']);