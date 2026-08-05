<?php
require_once __DIR__ . '/../index.php';

// Basic test assertions
assert(function_exists('VectorFactory::create'));
assert(function_exists('CacheFactory::create'));