<?php
namespace App\Services;

class CacheService
{
    private $adapter;

    public function __construct()
    {
        $type = env("CACHE_TYPE", "redis");
        if ($type === "local") {
            $this->adapter = new LocalCacheAdapter();
        } else {
            try {
                $this->adapter = new RedisCacheAdapter();
            } catch (\Exception $e) {
                $this->adapter = new LocalCacheAdapter();
            }
        }
    }

    public function get($key)
    {
        return $this->adapter->get($key);
    }

    public function set($key, $value, $ttl = 300)
    {
        $this->adapter->set($key, $value, $ttl);
    }

    public function delete($key)
    {
        $this->adapter->delete($key);
    }

    public function has($key)
    {
        return $this->adapter->has($key);
    }
}

class LocalCacheAdapter
{
    private $store = [];

    public function get($key)
    {
        if (!isset($this->store[$key])) return null;
        $entry = $this->store[$key];
        if ($entry["expires"] !== null && time() > $entry["expires"]) {
            unset($this->store[$key]);
            return null;
        }
        return $entry["value"];
    }

    public function set($key, $value, $ttl = 300)
    {
        $this->store[$key] = [
            "value" => $value,
            "expires" => $ttl ? time() + $ttl : null,
        ];
    }

    public function delete($key)
    {
        unset($this->store[$key]);
    }

    public function has($key)
    {
        return $this->get($key) !== null;
    }
}

class RedisCacheAdapter
{
    private $client;

    public function __construct()
    {
        $url = env("REDIS_URL", "redis://localhost:6379");
        $this->client = new \Predis\Client($url);
    }

    public function get($key)
    {
        $val = $this->client->get($key);
        if ($val === null) return null;
        return json_decode($val, true);
    }

    public function set($key, $value, $ttl = 300)
    {
        $this->client->setex($key, $ttl, json_encode($value));
    }

    public function delete($key)
    {
        $this->client->del([$key]);
    }

    public function has($key)
    {
        return $this->client->exists($key) > 0;
    }
}
