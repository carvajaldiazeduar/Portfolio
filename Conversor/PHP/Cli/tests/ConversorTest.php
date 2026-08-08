<?php

require_once __DIR__ . '/../conversor.php';

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

test('lengthConversion', function () {
    assert(abs(convert(1, "m", "cm") - 100) < 0.001);
});

test('weightConversion', function () {
    assert(abs(convert(1, "kg", "g") - 1000) < 0.001);
});

test('temperatureCtoF', function () {
    assert(abs(convert(0, "C", "F") - 32) < 0.001);
});

test('temperatureCtoK', function () {
    assert(abs(convert(0, "C", "K") - 273.15) < 0.001);
});

test('temperatureFtoC', function () {
    assert(abs(convert(32, "F", "C") - 0) < 0.001);
});

test('temperatureFtoK', function () {
    assert(abs(convert(32, "F", "K") - 273.15) < 0.001);
});

test('temperatureKtoC', function () {
    assert(abs(convert(273.15, "K", "C") - 0) < 0.001);
});

test('temperatureKtoF', function () {
    assert(abs(convert(273.15, "K", "F") - 32) < 0.001);
});

test('invalidUnit', function () {
    $thrown = false;
    try {
        convert(1, "m", "kg");
    } catch (InvalidArgumentException $e) {
        $thrown = true;
    }
    assert($thrown);
});

test('incompatibleCategories', function () {
    $thrown = false;
    try {
        convert(1, "m", "kg");
    } catch (InvalidArgumentException $e) {
        $thrown = true;
    }
    assert($thrown);
});

test('listCategories', function () {
    $cats = list_categories();
    assert(in_array("length", $cats, true));
    assert(in_array("weight", $cats, true));
    assert(in_array("temperature", $cats, true));
});

test('kmToMi', function () {
    assert(abs(convert(1, "km", "mi") - 0.621371) < 0.001);
});

test('lbToOz', function () {
    assert(abs(convert(1, "lb", "oz") - 16) < 0.001);
});

test('identity', function () {
    assert(abs(convert(100, "cm", "cm") - 100) < 0.001);
});

if ($fail > 0) {
    fwrite(STDERR, "{$fail} test(s) failed\n");
    exit(1);
}
echo "OK: {$pass} tests passed\n";
