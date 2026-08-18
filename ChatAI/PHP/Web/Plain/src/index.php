<?php

header("Content-Type: application/json");
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: DENY");

$method = $_SERVER["REQUEST_METHOD"];
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

$defaultModel = getenv("CHAT_MODEL") ?: "gpt-4o-mini";
$defaultTemperature = (float)(getenv("CHAT_TEMPERATURE") ?: 0.7);
$defaultMaxTokens = (int)(getenv("CHAT_MAX_TOKENS") ?: 1024);
$timeoutMs = (int)(getenv("CHAT_TIMEOUT_MS") ?: 30000);
$apiKey = getenv("OPENAI_API_KEY") ?: "";
$baseUrl = rtrim(getenv("OPENAI_BASE_URL") ?: "https://api.openai.com/v1", "/");
$ragEnabled = in_array(strtolower(getenv("RAG_ENABLED") ?: ""), ["1", "true", "yes"], true);
$ragSearchUrl = rtrim(getenv("RAG_SEARCH_URL") ?: "http://semantic-search:5000/api/search", "/");
$ragTopK = (int)(getenv("RAG_TOP_K") ?: 3);

function completeChat(array $messages, string $model, float $temperature, int $maxTokens, string $apiKey, string $baseUrl): array
{
    $payload = json_encode([
        "model" => $model,
        "messages" => $messages,
        "temperature" => $temperature,
        "max_tokens" => $maxTokens,
    ]);

    $headers = ["Content-Type: application/json"];
    if ($apiKey !== "") {
        $headers[] = "Authorization: Bearer " . $apiKey;
    }

    $context = stream_context_create([
        "http" => [
            "method" => "POST",
            "header" => implode("\r\n", $headers),
            "content" => $payload,
            "ignore_errors" => true,
        ],
    ]);

    $body = file_get_contents($baseUrl . "/chat/completions", false, $context);
    if ($body === false) {
        throw new RuntimeException("Provider request failed");
    }
    return json_decode($body, true) ?: [];
}

function retrieveContext(string $query, string $searchUrl, int $topK, float $timeoutSec): array
{
    $url = $searchUrl . "?q=" . urlencode($query) . "&k=" . $topK;
    $context = stream_context_create([
        "http" => [
            "method" => "GET",
            "timeout" => $timeoutSec,
            "ignore_errors" => true,
        ],
    ]);
    $body = file_get_contents($url, false, $context);
    if ($body === false) {
        return [];
    }
    $data = json_decode($body, true) ?: [];
    $documents = [];
    foreach (($data["results"] ?? []) as $result) {
        if (isset($result["document"]) && $result["document"] !== "") {
            $documents[] = $result["document"];
        }
    }
    return $documents;
}

if ($method === "GET" && ($path === "/" || $path === "/index.php")) {
    header("Content-Type: text/html");
    echo file_get_contents(__DIR__ . "/template.html");
    exit;
}

if ($method === "GET" && $path === "/health") {
    echo json_encode(["status" => "ok"]);
    exit;
}

if ($method === "POST" && $path === "/api/chat") {
    $input = json_decode(file_get_contents("php://input"), true);

    if (!is_array($input) || empty($input["messages"])) {
        http_response_code(400);
        echo json_encode(["error" => "Messages must not be empty"]);
        exit;
    }

    $model = $input["model"] ?? $defaultModel;
    $temperature = isset($input["temperature"]) ? (float)$input["temperature"] : $defaultTemperature;
    $maxTokens = isset($input["max_tokens"]) ? (int)$input["max_tokens"] : $defaultMaxTokens;

    $messages = $input["messages"];
    if ($ragEnabled) {
        $lastUser = null;
        foreach (array_reverse($messages) as $message) {
            if (isset($message["role"]) && $message["role"] === "user") {
                $lastUser = $message["content"] ?? "";
                break;
            }
        }
        if ($lastUser !== null) {
            try {
                $documents = retrieveContext($lastUser, $ragSearchUrl, $ragTopK, $timeoutMs / 1000);
            } catch (Throwable $e) {
                $documents = [];
            }
            if (count($documents) > 0) {
                $context = "Use the following context to answer the user's question:\n\n"
                    . implode("\n", array_map(static fn($document) => "- " . $document, $documents));
                array_unshift($messages, ["role" => "system", "content" => $context]);
            }
        }
    }

    try {
        $result = completeChat($messages, $model, $temperature, $maxTokens, $apiKey, $baseUrl);
    } catch (Throwable $e) {
        http_response_code(502);
        echo json_encode(["error" => $e->getMessage()]);
        exit;
    }

    $choices = [];
    foreach (($result["choices"] ?? []) as $choice) {
        $choices[] = [
            "role" => $choice["message"]["role"] ?? "assistant",
            "content" => $choice["message"]["content"] ?? "",
        ];
    }
    $usage = $result["usage"] ?? [];

    echo json_encode([
        "id" => $result["id"] ?? "",
        "model" => $result["model"] ?? $model,
        "choices" => $choices,
        "usage" => [
            "prompt_tokens" => $usage["prompt_tokens"] ?? 0,
            "completion_tokens" => $usage["completion_tokens"] ?? 0,
            "total_tokens" => $usage["total_tokens"] ?? 0,
        ],
    ]);
    exit;
}

http_response_code(404);
echo json_encode(["error" => "Not found"]);
