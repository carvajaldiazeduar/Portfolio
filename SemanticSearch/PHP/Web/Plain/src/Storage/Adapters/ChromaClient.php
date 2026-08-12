<?php
namespace Chroma;

class Client {
    private string $base;

    public function __construct(string $host = 'localhost', int $port = 8000) {
        $host = $host ?: 'localhost';
        $port = $port ?: 8000;
        $this->base = rtrim("http://{$host}:{$port}", '/') . '/api/v1';
    }

    public function request(string $method, string $path, array $body = null) {
        $url = $this->base . $path;
        $header = "Content-Type: application/json\r\n";
        $opts = [
            'http' => [
                'method' => $method,
                'header' => $header,
                'ignore_errors' => true,
                'timeout' => 5,
            ],
        ];
        if ($body !== null) {
            $opts['http']['content'] = json_encode($body);
        }
        $ctx = stream_context_create($opts);
        $resp = @file_get_contents($url, false, $ctx);
        if ($resp === false) {
            return null;
        }
        $decoded = json_decode($resp, true);
        if (!is_array($decoded)) {
            return null;
        }
        return $decoded;
    }

    public function getOrCreateCollection(string $name): Collection {
        $existing = $this->request('GET', '/collections/' . urlencode($name));
        if ($existing === null) {
            $created = $this->request('POST', '/collections', ['name' => $name, 'get_or_create' => true]);
            $existing = $created ?? ['name' => $name, 'id' => $name];
        }
        return new Collection($this, $existing['id'] ?? $name, $existing['name'] ?? $name);
    }

    public function deleteCollection(string $name): void {
        $col = $this->getOrCreateCollection($name);
        $this->request('DELETE', '/collections/' . urlencode($col->id));
    }

    public function listCollections(): array {
        $data = $this->request('GET', '/collections') ?: [];
        if (!is_array($data)) {
            return [];
        }
        return array_map(
            fn($c) => new Collection($this, $c['id'] ?? $c['name'], $c['name'] ?? $c['id']),
            $data
        );
    }
}

class Collection {
    public string $name;
    public $id;
    private Client $client;

    public function __construct(Client $client, $id, string $name) {
        $this->client = $client;
        $this->id = $id;
        $this->name = $name;
    }

    public function add(array $documents, array $embeddings, array $metadatas, array $ids): void {
        $this->client->request('POST', '/collections/' . urlencode($this->id) . '/add', [
            'ids' => $ids,
            'embeddings' => $embeddings,
            'documents' => $documents,
            'metadatas' => $metadatas,
        ]);
    }

    public function query(array $queryEmbeddings, int $nResults = 5): array {
        $resp = $this->client->request('POST', '/collections/' . urlencode($this->id) . '/query', [
            'query_embeddings' => $queryEmbeddings,
            'n_results' => $nResults,
        ]);
        if ($resp === null) {
            return ['documents' => [[]], 'metadatas' => [[]], 'distances' => [[]]];
        }
        return $resp;
    }
}
