<?php
require_once __DIR__ . '/../DatabaseAdapter.php';

class MongoDB implements DatabaseAdapter {
    private ?MongoDB\Database $db = null;

    public function connect(): void {
        $host = getenv('DB_HOST') ?: 'localhost';
        $port = getenv('DB_PORT') ?: '27017';
        $name = getenv('DB_NAME') ?: 'inboxes';
        $mongoClient = new MongoDB\Client("mongodb://$host:$port");
        $this->db = $mongoClient->selectDatabase($name);
    }

    private function getCollection(string $table): MongoDB\Collection {
        return $this->db->$table;
    }

    private function docToArray($doc): array {
        $arr = $doc->getArrayCopy();
        $arr['id'] = (string)$doc['_id'];
        unset($arr['_id']);
        return $arr;
    }

    public function getAll(string $table): array {
        $docs = $this->getCollection($table)->find([], ['sort' => ['_id' => 1]])->toArray();
        return array_map([$this, 'docToArray'], $docs);
    }

    public function getById(string $table, int|string $id): ?array {
        $doc = $this->getCollection($table)->findOne(['_id' => new MongoDB\BSON\ObjectId((string)$id)]);
        if (!$doc) return null;
        return $this->docToArray($doc);
    }

    public function create(string $table, array $data): int|string {
        $result = $this->getCollection($table)->insertOne($data);
        return (string)$result->getInsertedId();
    }

    public function update(string $table, int|string $id, array $data): bool {
        $result = $this->getCollection($table)->updateOne(
            ['_id' => new MongoDB\BSON\ObjectId((string)$id)],
            ['$set' => $data]
        );
        return $result->getModifiedCount() > 0 || $result->getMatchedCount() > 0;
    }

    public function delete(string $table, int|string $id): bool {
        $result = $this->getCollection($table)->deleteOne(['_id' => new MongoDB\BSON\ObjectId((string)$id)]);
        return $result->getDeletedCount() > 0;
    }

    public function search(string $table, string $field, string $query): array {
        $docs = $this->getCollection($table)->find(
            [$field => new MongoDB\BSON\Regex($query, 'i')],
            ['sort' => ['_id' => 1]]
        )->toArray();
        return array_map([$this, 'docToArray'], $docs);
    }
}

