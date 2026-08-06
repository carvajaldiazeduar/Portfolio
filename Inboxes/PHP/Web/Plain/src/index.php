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

if ($path === '/openapi.json') {
    header('Content-Type: application/json');
    readfile(__DIR__ . '/openapi.json');
    exit;
}

if ($path === '/swagger') {
    header('Content-Type: text/html');
    readfile(__DIR__ . '/swagger.html');
    exit;
}

header('Content-Type: application/json');

if ($path === '/' || $path === '/index.php') {
    header('Content-Type: text/html');
    echo file_get_contents(__DIR__ . '/template.html');
    exit;
}

if ($path === '/api/messages' && $method === 'GET') {
    $cached = $cache->get('messages:all');
    if ($cached !== null) { echo json_encode($cached); exit; }
    $msgs = $db->getAll('messages');
    $cache->set('messages:all', $msgs);
    echo json_encode($msgs);
    exit;
}

if ($path === '/api/messages' && $method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input || empty($input['subject'])) {
        http_response_code(400); echo json_encode(["error" => "Subject is required"]); exit;
    }
    $id = $db->create('messages', [
        'sender' => $input['sender'] ?? '',
        'subject' => $input['subject'],
        'body' => $input['body'] ?? '',
        'read' => 0
    ]);
    $msg = ['id' => $id, 'sender' => $input['sender'] ?? '', 'subject' => $input['subject'], 'body' => $input['body'] ?? '', 'read' => false];
    $cache->delete('messages:all');
    http_response_code(201);
    echo json_encode($msg);
    exit;
}

if (preg_match('#^/api/messages/(\d+)$#', $path, $matches) && $method === 'GET') {
    $id = (int) $matches[1];
    $cached = $cache->get("message:$id");
    if ($cached !== null) { echo json_encode($cached); exit; }
    $msg = $db->getById('messages', $id);
    if (!$msg) { http_response_code(404); echo json_encode(["error" => "Not found"]); exit; }
    $db->update('messages', $id, ['read' => 1]);
    $msg['read'] = true;
    $cache->set("message:$id", $msg);
    $cache->delete('messages:all');
    echo json_encode($msg);
    exit;
}

if (preg_match('#^/api/messages/(\d+)$#', $path, $matches) && $method === 'DELETE') {
    $id = (int) $matches[1];
    $deleted = $db->delete('messages', $id);
    if ($deleted) {
        $cache->delete('messages:all'); $cache->delete("message:$id");
        http_response_code(204);
    } else {
        http_response_code(404); echo json_encode(["error" => "Not found"]);
    }
    exit;
}

http_response_code(404);
echo json_encode(["error" => "Not found"]);

