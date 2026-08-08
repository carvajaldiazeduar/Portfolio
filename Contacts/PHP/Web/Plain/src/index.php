<?php
require_once __DIR__ . '/Storage/DatabaseFactory.php';
require_once __DIR__ . '/Cache/CacheAdapter.php';
require_once __DIR__ . '/Cache/CacheFactory.php';
require_once __DIR__ . '/Cache/Adapters/Local.php';
require_once __DIR__ . '/Cache/Adapters/Redis.php';

function validateContact(array $input): array {
    $errors = [];
    $name = trim($input['name'] ?? '');
    $phone = trim($input['phone'] ?? '');
    $email = trim($input['email'] ?? '');
    if ($name === '') {
        $errors['name'] = 'Name is required';
    } elseif (strlen($name) < 2 || strlen($name) > 100 || !preg_match('/^[A-Za-zÀ-ÿ\' .-]+$/', $name)) {
        $errors['name'] = 'Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)';
    }
    if ($phone === '') {
        $errors['phone'] = 'Phone is required';
    } elseif (!preg_match('/^[0-9 +().-]{7,20}$/', $phone)) {
        $errors['phone'] = 'Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)';
    }
    if ($email === '') {
        $errors['email'] = 'Email is required';
    } elseif (!preg_match('/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/', $email)) {
        $errors['email'] = 'Invalid email format';
    }
    return $errors;
}

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
    if (!is_array($input)) {
        $input = [];
    }
    $errors = validateContact($input);
    if ($errors) {
        http_response_code(400);
        echo json_encode(["errors" => $errors]);
        exit;
    }
    $name = trim($input['name']);
    $phone = trim($input['phone']);
    $email = trim($input['email']);
    $id = $db->create('contacts', [
        'name' => $name,
        'phone' => $phone,
        'email' => $email
    ]);
    $contact = ['id' => $id, 'name' => $name, 'phone' => $phone, 'email' => $email];
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

