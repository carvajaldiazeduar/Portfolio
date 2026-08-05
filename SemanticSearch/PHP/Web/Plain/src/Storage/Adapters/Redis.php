<?php
require_once __DIR__ . '/../CacheAdapter.php';
require_once __DIR__ . '/Local.php';

class Redis implements CacheAdapter {
    private ?Redis $redis = null;
    private Local $fallback;

    public function __construct() {
        $this->fallback = new Local();
    }

    private function connect(): ?Redis {
        if ($this->redis !== null) return $this->redis;
        try {
            $this->redis = new Redis();
            $this->redis->connect(
                getenv('REDIS_HOST') ?: 'redis',
                (int)(getenv('REDIS_PORT') ?: 6379)
            );
            return $this->redis;
        } catch (Exception $e) {
            return null;
        }
    }

    public function get(string $key): mixed {
        $r = $this->connect();
        if (!$r) return $this->fallback->get($key);
        $v = $r->get($key);
        return $v !== false ? json_decode($v, true) : $this->fallback->get($key);
    }

    public function set(string $key, mixed $value, int $ttl = 300): void {
        $this->fallback->set($key, $value, $ttl);
        $r = $this->connect();
        if ($r) {
            $r->setex($key, $ttl, json_encode($value));
        }
    }

    public function delete(string $key): void {
        $this->fallback->delete($key);
        $r = $this->connect();
        if ($r) {
            $r->del($key);
        }
    }
}