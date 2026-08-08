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

test('generateDefault', function () {
    $res = httpRequest('POST', 'http://127.0.0.1:8000/api/generate', ["length" => 16]);
    assert(strlen($res["body"]["password"] ?? "") === 16);
});

test('generateCustomLength', function () {
    $res = httpRequest('POST', 'http://127.0.0.1:8000/api/generate', ["length" => 24]);
    assert(strlen($res["body"]["password"] ?? "") === 24);
});

test('generateNoUppercase', function () {
    $res = httpRequest('POST', 'http://127.0.0.1:8000/api/generate', ["length" => 16, "use_upper" => false]);
    assert(preg_match('/[A-Z]/', $res["body"]["password"] ?? '') === 0);
});

test('generateNoSymbols', function () {
    $res = httpRequest('POST', 'http://127.0.0.1:8000/api/generate', ["length" => 16, "use_symbols" => false]);
    assert(preg_match('/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', $res["body"]["password"] ?? '') === 0);
});

test('generateAllDisabledThrows', function () {
    $res = httpRequest('POST', 'http://127.0.0.1:8000/api/generate', ["length" => 10, "use_upper" => false, "use_lower" => false, "use_digits" => false, "use_symbols" => false]);
    assert($res["status"] === 400);
});

test('generateNegativeLengthThrows', function () {
    $res = httpRequest('POST', 'http://127.0.0.1:8000/api/generate', ["length" => -1]);
    assert($res["status"] === 400);
});

test('generateAtLeastOneFromEach', function () {
    $res = httpRequest('POST', 'http://127.0.0.1:8000/api/generate', ["length" => 20, "use_symbols" => true]);
    $pw = $res["body"]["password"] ?? '';
    assert(strlen($pw) === 20);
    assert(preg_match('/[^A-Za-z0-9!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', $pw) === 0);
});

if ($fail > 0) {
    fwrite(STDERR, "{$fail} test(s) failed\n");
    exit(1);
}
echo "OK: {$pass} tests passed\n";
