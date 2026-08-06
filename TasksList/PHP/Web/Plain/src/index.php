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

if ($path === '/api/tasks' && $method === 'GET') {
    $cached = $cache->get('tasks:all');
    if ($cached !== null) { echo json_encode($cached); exit; }
    $tasks = $db->getAll('tasks');
    $cache->set('tasks:all', $tasks);
    echo json_encode($tasks);
    exit;
}

if ($path === '/api/tasks' && $method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input || empty($input['title'])) {
        http_response_code(400); echo json_encode(["error" => "Title is required"]); exit;
    }
    $id = $db->create('tasks', [
        'title' => $input['title'],
        'description' => $input['description'] ?? '',
        'completed' => 0
    ]);
    $task = ['id' => $id, 'title' => $input['title'], 'description' => $input['description'] ?? '', 'completed' => false];
    $cache->delete('tasks:all');
    http_response_code(201);
    echo json_encode($task);
    exit;
}

if (preg_match('#^/api/tasks/(\d+)/complete$#', $path, $matches) && $method === 'PUT') {
    $id = (int) $matches[1];
    $updated = $db->update('tasks', $id, ['completed' => 1]);
    if ($updated) {
        $cache->delete('tasks:all');
        echo json_encode(["message" => "Completed"]);
    } else {
        http_response_code(404); echo json_encode(["error" => "Not found"]);
    }
    exit;
}

if (preg_match('#^/api/tasks/(\d+)$#', $path, $matches) && $method === 'DELETE') {
    $id = (int) $matches[1];
    $deleted = $db->delete('tasks', $id);
    if ($deleted) {
        $cache->delete('tasks:all');
        echo json_encode(["message" => "Deleted"]);
    } else {
        http_response_code(404); echo json_encode(["error" => "Not found"]);
    }
    exit;
}

http_response_code(404);
echo json_encode(["error" => "Not found"]);

