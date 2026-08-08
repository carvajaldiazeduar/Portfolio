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

test('invalidEmailReturnsError', function () {
    $errors = validateContact(["name" => "Alice", "phone" => "123-4567", "email" => "not-an-email"]);
    assert($errors === ["email" => "Invalid email format"]);
});

test('invalidPhoneReturnsError', function () {
    $errors = validateContact(["name" => "Alice", "phone" => "abc", "email" => "alice@test.com"]);
    assert($errors === ["phone" => "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"]);
});

test('missingNameReturnsError', function () {
    $errors = validateContact(["name" => "", "phone" => "123-4567", "email" => "alice@test.com"]);
    assert($errors === ["name" => "Name is required"]);
});

test('validContactHasNoErrors', function () {
    $errors = validateContact(["name" => "Alice", "phone" => "123-4567", "email" => "alice@test.com"]);
    assert($errors === []);
});

if ($fail > 0) {
    fwrite(STDERR, "{$fail} test(s) failed\n");
    exit(1);
}
echo "OK: {$pass} tests passed\n";
