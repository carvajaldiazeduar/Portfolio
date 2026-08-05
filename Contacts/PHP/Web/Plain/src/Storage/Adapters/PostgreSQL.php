<?php
require_once __DIR__ . '/../DatabaseAdapter.php';

class PostgreSQL implements DatabaseAdapter {
    private ?PDO $pdo = null;

    public function connect(): void {
        $host = getenv('DB_HOST') ?: 'db';
        $port = getenv('DB_PORT') ?: '5432';
        $name = getenv('DB_NAME') ?: 'contacts';
        $user = getenv('DB_USER') ?: 'postgres';
        $pass = getenv('DB_PASSWORD') ?: 'postgres';
        $this->pdo = new PDO("pgsql:host=$host;port=$port;dbname=$name", $user, $pass);
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        $this->pdo->exec("CREATE TABLE IF NOT EXISTS contacts (id SERIAL PRIMARY KEY, name TEXT NOT NULL, phone TEXT DEFAULT '', email TEXT DEFAULT '')");
    }

    public function getAll(string $table): array {
        $stmt = $this->pdo->query("SELECT * FROM \"$table\" ORDER BY id ASC");
        return $stmt->fetchAll();
    }

    public function getById(string $table, int|string $id): ?array {
        $stmt = $this->pdo->prepare("SELECT * FROM \"$table\" WHERE id = ?");
        $stmt->execute([$id]);
        $result = $stmt->fetch();
        return $result ?: null;
    }

    public function create(string $table, array $data): int|string {
        $columns = implode(', ', array_keys($data));
        $placeholders = implode(', ', array_fill(0, count($data), '?'));
        $stmt = $this->pdo->prepare("INSERT INTO \"$table\" ($columns) VALUES ($placeholders) RETURNING id");
        $stmt->execute(array_values($data));
        return (int)$stmt->fetch()['id'];
    }

    public function update(string $table, int|string $id, array $data): bool {
        $sets = implode(', ', array_map(fn($col) => "\"$col\" = ?", array_keys($data)));
        $stmt = $this->pdo->prepare("UPDATE \"$table\" SET $sets WHERE id = ?");
        $stmt->execute([...array_values($data), $id]);
        return $stmt->rowCount() > 0;
    }

    public function delete(string $table, int|string $id): bool {
        $stmt = $this->pdo->prepare("DELETE FROM \"$table\" WHERE id = ?");
        $stmt->execute([$id]);
        return $stmt->rowCount() > 0;
    }

    public function search(string $table, string $field, string $query): array {
        $stmt = $this->pdo->prepare("SELECT * FROM \"$table\" WHERE LOWER(\"$field\") LIKE ? ORDER BY id ASC");
        $stmt->execute(["%$query%"]);
        return $stmt->fetchAll();
    }
}

