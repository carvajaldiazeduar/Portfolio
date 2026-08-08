<?php

require_once __DIR__ . '/../calculator.php';

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

test('add', function () {
    assert(add(2, 3) == 5);
    assert(add(-1, 1) == 0);
    assert(add(0, 0) == 0);
});

test('subtract', function () {
    assert(subtract(5, 3) == 2);
    assert(subtract(0, 5) == -5);
    assert(subtract(-1, -1) == 0);
});

test('multiply', function () {
    assert(multiply(2, 3) == 6);
    assert(multiply(0, 5) == 0);
    assert(multiply(-2, 3) == -6);
});

test('divide', function () {
    assert(divide(6, 3) == 2);
    assert(abs(divide(5, 2) - 2.5) < 1e-9);
    assert(divide(0, 5) == 0);
});

test('divideByZero', function () {
    assert(divide(5, 0) === 'Error: Cannot divide by zero');
});

if ($fail > 0) {
    fwrite(STDERR, "{$fail} test(s) failed\n");
    exit(1);
}
echo "OK: {$pass} tests passed\n";
