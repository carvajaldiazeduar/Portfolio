<?php

header("Content-Type: application/json");
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: DENY");

$path = parse_url($_SERVER["REQUEST_URI"], PHP_URL_PATH);

if ($path === "/openapi.json") {
    header("Content-Type: application/json");
    readfile(__DIR__ . "/openapi.json");
    exit;
}

if ($path === "/swagger") {
    header("Content-Type: text/html");
    readfile(__DIR__ . "/swagger.html");
    exit;
}

function calculate(float $a, float $b, string $operator): float|string|null
{
    return match ($operator) {
        "add" => $a + $b,
        "subtract" => $a - $b,
        "multiply" => $a * $b,
        "divide" => $b == 0 ? null : $a / $b,
        default => null,
    };
}

if ($_SERVER["REQUEST_METHOD"] === "GET") {
    header("Content-Type: text/html");
    echo file_get_contents(__DIR__ . "/template.html");
    exit;
}

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    echo json_encode(["error" => "Method not allowed"]);
    exit;
}

$input = json_decode(file_get_contents("php://input"), true);

if ($input === null) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid JSON"]);
    exit;
}

$allowedOperators = ["add", "subtract", "multiply", "divide"];
$operator = $input["operator"] ?? "";

if (!in_array($operator, $allowedOperators)) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid operator"]);
    exit;
}

if (!isset($input["a"]) || !isset($input["b"]) || !is_numeric($input["a"]) || !is_numeric($input["b"])) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid number input"]);
    exit;
}

$a = (float) $input["a"];
$b = (float) $input["b"];
$result = calculate($a, $b, $operator);

if ($operator === "divide" && $b == 0) {
    http_response_code(400);
    echo json_encode(["error" => "Cannot divide by zero"]);
    exit;
}

if ($result === null) {
    http_response_code(400);
    echo json_encode(["error" => "Calculation error"]);
    exit;
}

echo json_encode(["result" => $result]);
