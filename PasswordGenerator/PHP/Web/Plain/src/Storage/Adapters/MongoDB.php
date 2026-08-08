<?php
require_once __DIR__ . '/../DatabaseAdapter.php';

class MongoDB implements DatabaseAdapter {
    private ?MongoDB\Driver\Manager $manager = null;
    private string $dbName;

    public function connect(): void {
        $host = getenv('DB_HOST') ?: 'localhost';
        $port = getenv('DB_PORT') ?: '27017';
        $name = getenv('DB_NAME') ?: 'passwords';
        $this->dbName = $name;
        $this->manager = new MongoDB\Driver\Manager("mongodb://$host:$port");
    }

    private function ns(string $table): string {
        return "{$this->dbName}.$table";
    }

    private function toId(int|string $id): ?MongoDB\BSON\ObjectId {
        try {
            return new MongoDB\BSON\ObjectId((string) $id);
        } catch (Throwable) {
            return null;
        }
    }

    private function docToArray(object $doc): array {
        $arr = [];
        foreach ((array) $doc as $k => $v) {
            if ($k === '_id') {
                $arr['id'] = is_object($v) && method_exists($v, '__toString') ? (string) $v : (is_scalar($v) ? $v : null);
                continue;
            }
            if (is_object($v)) {
                $arr[$k] = method_exists($v, '__toString') ? (string) $v : null;
            } elseif (is_array($v)) {
                $arr[$k] = array_map(fn($x) => (is_object($x) && method_exists($x, '__toString')) ? (string) $x : $x, $v);
            } else {
                $arr[$k] = $v;
            }
        }
        return $arr;
    }

    public function getAll(string $table): array {
        $query = new MongoDB\Driver\Query([], ['sort' => ['_id' => 1]]);
        $cursor = $this->manager->executeQuery($this->ns($table), $query);
        $out = [];
        foreach ($cursor as $doc) { $out[] = $this->docToArray($doc); }
        return $out;
    }

    public function getById(string $table, int|string $id): ?array {
        $oid = $this->toId($id);
        if ($oid === null) return null;
        $query = new MongoDB\Driver\Query(['_id' => $oid], ['limit' => 1]);
        $cursor = $this->manager->executeQuery($this->ns($table), $query);
        $doc = $cursor->toArray();
        if (!$doc) return null;
        return $this->docToArray($doc[0]);
    }

    public function create(string $table, array $data): int|string {
        $doc = $data;
        $doc['_id'] = new MongoDB\BSON\ObjectId();
        $bulk = new MongoDB\Driver\BulkWrite();
        $bulk->insert($doc);
        $this->manager->executeBulkWrite($this->ns($table), $bulk);
        return (string) $doc['_id'];
    }

    public function update(string $table, int|string $id, array $data): bool {
        $oid = $this->toId($id);
        if ($oid === null) return false;
        $bulk = new MongoDB\Driver\BulkWrite();
        $bulk->update(['_id' => $oid], ['$set' => $data]);
        $res = $this->manager->executeBulkWrite($this->ns($table), $bulk);
        return $res->getMatchedCount() > 0 || $res->getModifiedCount() > 0;
    }

    public function delete(string $table, int|string $id): bool {
        $oid = $this->toId($id);
        if ($oid === null) return false;
        $bulk = new MongoDB\Driver\BulkWrite();
        $bulk->delete(['_id' => $oid]);
        $res = $this->manager->executeBulkWrite($this->ns($table), $bulk);
        return $res->getDeletedCount() > 0;
    }

    public function search(string $table, string $field, string $query): array {
        $filter = [$field => ['$regex' => $query, '$options' => 'i']];
        $q = new MongoDB\Driver\Query($filter, ['sort' => ['_id' => 1]]);
        $cursor = $this->manager->executeQuery($this->ns($table), $q);
        $out = [];
        foreach ($cursor as $doc) { $out[] = $this->docToArray($doc); }
        return $out;
    }
}
