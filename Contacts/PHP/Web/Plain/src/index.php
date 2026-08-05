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

if ($path === '/api/contacts' && $method === 'GET') {
    $cached = $cache->get('contacts:all');
    if ($cached !== null) { echo json_encode($cached); exit; }
    $contacts = $db->getAll('contacts');
    $cache->set('contacts:all', $contacts);
    echo json_encode($contacts);
    exit;
}

if ($path === '/api/contacts' && $method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input || empty($input['name'])) {
        http_response_code(400);
        echo json_encode(["error" => "Name is required"]);
        exit;
    }
    $id = $db->create('contacts', [
        'name' => $input['name'],
        'phone' => $input['phone'] ?? '',
        'email' => $input['email'] ?? ''
    ]);
    $contact = ['id' => $id, 'name' => $input['name'], 'phone' => $input['phone'] ?? '', 'email' => $input['email'] ?? ''];
    $cache->delete('contacts:all');
    http_response_code(201);
    echo json_encode($contact);
    exit;
}

if ($path === '/api/contacts/search' && $method === 'GET') {
    $q = strtolower($_GET['q'] ?? '');
    $cached = $cache->get("contacts:search:$q");
    if ($cached !== null) { echo json_encode($cached); exit; }
    $results = $db->search('contacts', 'name', $q);
    $cache->set("contacts:search:$q", $results);
    echo json_encode($results);
    exit;
}

if (preg_match('#^/api/contacts/(\d+)$#', $path, $matches) && $method === 'DELETE') {
    $id = (int) $matches[1];
    $deleted = $db->delete('contacts', $id);
    if ($deleted) {
        $cache->delete('contacts:all');
        echo json_encode(["message" => "Deleted"]);
    } else {
        http_response_code(404);
        echo json_encode(["error" => "Not found"]);
    }
    exit;
}

http_response_code(404);
echo json_encode(["error" => "Not found"]);

