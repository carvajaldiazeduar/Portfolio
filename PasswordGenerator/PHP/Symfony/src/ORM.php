<?php
namespace App;

class ORM
{
    private static $pdo;
    private $table;
    private $data = [];
    private $where = [];
    private $params = [];
    private $limit = null;

    public static function connect(string $url = null)
    {
        $url = $url ?? $_ENV['DATABASE_URL'] ?? $_SERVER['DATABASE_URL'] ?? 'sqlite:///' . __DIR__ . '/data.db';
        $parts = parse_url($url);
        $scheme = $parts['scheme'] ?? 'sqlite';
        if ($scheme === 'sqlite') {
            $path = $parts['path'] ?? __DIR__ . '/data.db';
            self::$pdo = new \PDO("sqlite:$path");
        } elseif ($scheme === 'postgresql' || $scheme === 'postgres') {
            $dsn = "pgsql:host={$parts['host']};port={$parts['port']};dbname=" . ltrim($parts['path'], '/');
            self::$pdo = new \PDO($dsn, $parts['user'] ?? 'postgres', $parts['pass'] ?? 'postgres');
        } elseif ($scheme === 'mysql') {
            $dsn = "mysql:host={$parts['host']};port={$parts['port']};dbname=" . ltrim($parts['path'], '/');
            self::$pdo = new \PDO($dsn, $parts['user'] ?? 'root', $parts['pass'] ?? '');
        } else {
            throw new \Exception("Unsupported database scheme: $scheme");
        }
        self::$pdo->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
        self::$pdo->setAttribute(\PDO::ATTR_DEFAULT_FETCH_MODE, \PDO::FETCH_ASSOC);
    }

    public static function table(string $name): self
    {
        $instance = new self();
        $instance->table = $name;
        return $instance;
    }

    public function where(string $column, $value): self
    {
        $this->where[] = "$column = ?";
        $this->params[] = $value;
        return $this;
    }

    public function limit(int $n): self
    {
        $this->limit = $n;
        return $this;
    }

    public function get(): array
    {
        $sql = "SELECT * FROM {$this->table}";
        if ($this->where) {
            $sql .= " WHERE " . implode(' AND ', $this->where);
        }
        $sql .= " ORDER BY id ASC";
        if ($this->limit) {
            $sql .= " LIMIT " . $this->limit;
        }
        $stmt = self::$pdo->prepare($sql);
        $stmt->execute($this->params);
        return $stmt->fetchAll();
    }

    public function first(): ?array
    {
        $this->limit(1);
        $results = $this->get();
        return $results[0] ?? null;
    }

    public function create(array $data): array
    {
        $columns = implode(', ', array_keys($data));
        $placeholders = implode(', ', array_fill(0, count($data), '?'));
        $stmt = self::$pdo->prepare("INSERT INTO {$this->table} ($columns) VALUES ($placeholders)");
        $stmt->execute(array_values($data));
        $data['id'] = (int) self::$pdo->lastInsertId();
        $this->data = $data;
        return $data;
    }

    public function update(array $data): bool
    {
        $sets = implode(', ', array_map(fn($c) => "$c = ?", array_keys($data)));
        $params = array_values($data);
        if ($this->where) {
            $params = array_merge($params, $this->params);
            $sql = "UPDATE {$this->table} SET $sets WHERE " . implode(' AND ', $this->where);
        } else {
            return false;
        }
        $stmt = self::$pdo->prepare($sql);
        return $stmt->execute($params);
    }

    public function delete(): bool
    {
        if (!$this->where) return false;
        $sql = "DELETE FROM {$this->table} WHERE " . implode(' AND ', $this->where);
        $stmt = self::$pdo->prepare($sql);
        return $stmt->execute($this->params);
    }

    public static function raw(string $sql, array $params = []): array
    {
        $stmt = self::$pdo->prepare($sql);
        $stmt->execute($params);
        if (stripos($sql, 'SELECT') === 0) {
            return $stmt->fetchAll();
        }
        return [];
    }
}
