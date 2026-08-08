<?php

$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['REQUEST_URI'] = '/__unittest__';

ob_start();
require_once __DIR__ . '/../index.php';
ob_end_clean();

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

test('categoriesEndpoint', function () {
    global $CATEGORY_UNITS;
    assert(array_key_exists('length', $CATEGORY_UNITS));
    assert(array_key_exists('weight', $CATEGORY_UNITS));
    assert(array_key_exists('temperature', $CATEGORY_UNITS));
});

test('convertLength', function () {
    assert(abs(convert(1, "m", "cm") - 100) < 0.001);
});

test('convertInvalid', function () {
    $thrown = false;
    try {
        convert(1, "m", "kg");
    } catch (InvalidArgumentException $e) {
        $thrown = true;
    }
    assert($thrown);
});

if ($fail > 0) {
    fwrite(STDERR, "{$fail} test(s) failed\n");
    exit(1);
}
echo "OK: {$pass} tests passed\n";
