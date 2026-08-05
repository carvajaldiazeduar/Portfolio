<?php
require_once __DIR__ . '/../CacheAdapter.php';

class Local implements CacheAdapter {
    private static array $store = [];

    public function get(string $key): mixed {
        if (!isset(self::$store[$key])) return null;
        if (self::$store[$key]['exp'] < time()) {
            unset(self::$store[$key]);
            return null;
        }
        return self::$store[$key]['val'];
    }

    public function set(string $key, mixed $value, int $ttl = 300): void {
        self::$store[$key] = ['val' => $value, 'exp' => time() + $ttl];
    }

    public function delete(string $key): void {
        unset(self::$store[$key]);
    }
}