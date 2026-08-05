<?php
require_once __DIR__ . '/../Cli/conversor.php';

header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

if ($method === 'GET' && ($path === '/' || $path === '')) {
    header('Content-Type: text/html');
    readfile(__DIR__ . '/template.html');
    exit;
}

if ($method === 'GET' && $path === '/api/categories') {
    global $CATEGORY_UNITS;
    echo json_encode($CATEGORY_UNITS);
    exit;
}

if ($method === 'POST' && $path === '/api/convert') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid JSON']);
        exit;
    }
    $value = $input['value'] ?? null;
    $from = $input['from'] ?? null;
    $to = $input['to'] ?? null;
    if ($value === null || !$from || !$to) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing fields: value, from, to']);
        exit;
    }
    try {
        $result = convert((float)$value, $from, $to);
        echo json_encode(['result' => $result, 'from' => $from, 'to' => $to, 'value' => (float)$value]);
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit;
}

http_response_code(404);
echo json_encode(['error' => 'Not found']);
