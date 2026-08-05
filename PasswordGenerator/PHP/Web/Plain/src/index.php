<?php
require_once __DIR__ . '/Storage/DatabaseFactory.php';
require_once __DIR__ . '/Cache/CacheAdapter.php';
require_once __DIR__ . '/Cache/Adapters/Local.php';
require_once __DIR__ . '/Cache/Adapters/Redis.php';

$db = DatabaseFactory::create();
$db->connect();

$cache = CacheFactory::create();

$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

header('Content-Type: application/json');

if ($path === '/' || $path === '/index.php') {
    header('Content-Type: text/html');
    echo file_get_contents(__DIR__ . '/template.html');
    exit;
}

if ($path === '/api/generate' && $method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input || !isset($input['length'])) {
        http_response_code(400); echo json_encode(["error" => "Length is required"]); exit;
    }
    $length = (int) $input['length'];
    if ($length < 4 || $length > 128) {
        http_response_code(400); echo json_encode(["error" => "Length must be 4-128"]); exit;
    }
    $useUpper = $input['use_upper'] ?? true;
    $useLower = $input['use_lower'] ?? true;
    $useDigits = $input['use_digits'] ?? true;
    $useSymbols = $input['use_symbols'] ?? false;
    $chars = '';
    if ($useUpper) $chars .= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if ($useLower) $chars .= 'abcdefghijklmnopqrstuvwxyz';
    if ($useDigits) $chars .= '0123456789';
    if ($useSymbols) $chars .= '!@#$%^&*()_+-=[]{}|;:,.<>?';
    if ($chars === '') {
        http_response_code(400); echo json_encode(["error" => "Select at least one character type"]); exit;
    }
    $password = '';
    $max = strlen($chars) - 1;
    for ($i = 0; $i < $length; $i++) {
        $password .= $chars[random_int(0, $max)];
    }
    $db->create('password_entries', ['password' => $password, 'length' => $length]);
    $cache->delete('passwords:recent');
    echo json_encode(['password' => $password]);
    exit;
}

if ($path === '/api/passwords' && $method === 'GET') {
    $cached = $cache->get('passwords:recent');
    if ($cached !== null) { echo json_encode($cached); exit; }
    $entries = $db->getAll('password_entries');
    $cache->set('passwords:recent', $entries);
    echo json_encode($entries);
    exit;
}

http_response_code(404);
echo json_encode(["error" => "Not found"]);

