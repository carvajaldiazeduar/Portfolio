<?php
require_once __DIR__ . '/CacheAdapter.php';
require_once __DIR__ . '/Adapters/Local.php';
require_once __DIR__ . '/Adapters/Redis.php';

class CacheFactory {
    public static function create(): CacheAdapter {
        $cacheType = getenv('CACHE_TYPE') ?: 'redis';
        return $cacheType === 'local' ? new Local() : new RedisAdapter();
    }
}
