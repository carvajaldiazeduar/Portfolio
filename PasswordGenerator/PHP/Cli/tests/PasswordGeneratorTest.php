<?php

require_once __DIR__ . '/../password_generator.php';

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

test('defaultLength', function () {
    assert(strlen(generate_password()) === 16);
});

test('customLength', function () {
    assert(strlen(generate_password(24)) === 24);
});

test('minLength', function () {
    assert(strlen(generate_password(1, true, false, false, false)) === 1);
});

test('uppercasePresent', function () {
    assert(preg_match('/[A-Z]/', generate_password(10, true, false, false, false)) === 1);
});

test('lowercasePresent', function () {
    assert(preg_match('/[a-z]/', generate_password(10, false, true, false, false)) === 1);
});

test('digitsPresent', function () {
    assert(preg_match('/[0-9]/', generate_password(10, false, false, true, false)) === 1);
});

test('symbolsPresent', function () {
    assert(preg_match('/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', generate_password(10, false, false, false, true)) === 1);
});

test('noUppercase', function () {
    assert(preg_match('/[A-Z]/', generate_password(16, false)) === 0);
});

test('noSymbols', function () {
    assert(preg_match('/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', generate_password(16, true, true, true, false)) === 0);
});

test('noLowercase', function () {
    assert(preg_match('/[a-z]/', generate_password(16, false, false)) === 0);
});

test('noDigits', function () {
    assert(preg_match('/[0-9]/', generate_password(16, false, false, false)) === 0);
});

test('allDisabledThrows', function () {
    $thrown = false;
    try {
        generate_password(10, false, false, false, false);
    } catch (InvalidArgumentException $e) {
        $thrown = true;
    }
    assert($thrown);
});

test('lengthZeroThrows', function () {
    $thrown = false;
    try {
        generate_password(0);
    } catch (InvalidArgumentException $e) {
        $thrown = true;
    }
    assert($thrown);
});

test('negativeLengthThrows', function () {
    $thrown = false;
    try {
        generate_password(-5);
    } catch (InvalidArgumentException $e) {
        $thrown = true;
    }
    assert($thrown);
});

test('lengthTooShortForCategories', function () {
    $thrown = false;
    try {
        generate_password(2, true, true, true, true);
    } catch (InvalidArgumentException $e) {
        $thrown = true;
    }
    assert($thrown);
});

test('atLeastOneFromEachEnabled', function () {
    $pw = generate_password(20, true, true, true, true);
    assert(preg_match('/[A-Z]/', $pw) === 1);
    assert(preg_match('/[a-z]/', $pw) === 1);
    assert(preg_match('/[0-9]/', $pw) === 1);
    assert(preg_match('/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', $pw) === 1);
});

test('onlyUppercaseAndDigits', function () {
    $pw = generate_password(12, true, false, true, false);
    assert(preg_match('/[A-Z]/', $pw) === 1);
    assert(preg_match('/[0-9]/', $pw) === 1);
    assert(preg_match('/[a-z]/', $pw) === 0);
    assert(preg_match('/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', $pw) === 0);
});

test('shuffledNotSequential', function () {
    $passwords = [];
    for ($i = 0; $i < 5; $i++) {
        $passwords[] = generate_password();
    }
    $unique = array_unique($passwords);
    assert(count($unique) > 1);
});

if ($fail > 0) {
    fwrite(STDERR, "{$fail} test(s) failed\n");
    exit(1);
}
echo "OK: {$pass} tests passed\n";
