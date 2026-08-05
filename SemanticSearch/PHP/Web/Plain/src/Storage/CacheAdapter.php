<?php
interface CacheAdapter {
    public function get(string $key): mixed;
    public function set(string $key, mixed $value, int $ttl = 300): void;
    public function delete(string $key): void;
}