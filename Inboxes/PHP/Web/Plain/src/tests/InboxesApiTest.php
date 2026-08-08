<?php

$pass = 0;
$fail = 0;

function test(string $name, callable $fn): void {
    global $pass, $fail;
    try {
        $fn();
        $pass++;
        echo "PASS: $name\n";
    } catch (Throwable $e) {
        $fail++;
        fwrite(STDERR, "FAIL: $name - " . $e->getMessage() . "\n");
    }
}

function httpRequest(string $method, string $url, ?array $body = null): array {
    $opts = ["http" => ["method" => $method, "ignore_errors" => true, "timeout" => 5]];
    if ($body !== null) {
        $opts["http"]["header"] = "Content-Type: application/json\r\n";
        $opts["http"]["content"] = json_encode($body);
    }
    $ctx = stream_context_create($opts);
    $raw = @file_get_contents($url, false, $ctx);
    $status = 0;
    if (isset($http_response_header[0])) {
        preg_match('/HTTP\/\S+\s+(\d{3})/', $http_response_header[0], $m);
        if (isset($m[1])) { $status = (int) $m[1]; }
    }
    $data = json_decode($raw === false ? 'null' : $raw, true);
    return ["status" => $status, "body" => $data === null ? [] : $data, "raw" => $raw];
}

test('listEmpty', function () {
    $res = httpRequest('GET', 'http://127.0.0.1:8000/api/messages');
    assert($res["raw"] !== false);
    assert(is_array($res["body"]));
});

test('sendAndList', function () {
    $res = httpRequest('POST', 'http://127.0.0.1:8000/api/messages', ["sender" => "alice", "subject" => "Hello", "body" => "World"]);
    $id = $res["body"]["id"] ?? null;
    assert($id !== null && $id !== '');
    assert(($res["body"]["sender"] ?? null) === "alice");
    assert(($res["body"]["subject"] ?? null) === "Hello");
    assert(($res["body"]["body"] ?? null) === "World");
});

if ($fail > 0) {
    fwrite(STDERR, "{$fail} test(s) failed\n");
    exit(1);
}
echo "OK: {$pass} tests passed\n";
