<?php

$GLOBALS['CONVERSION'] = [
    "length" => [
        "m" => 1.0,
        "km" => 0.001,
        "mi" => 0.000621371,
        "ft" => 3.28084,
        "in" => 39.3701,
        "cm" => 100.0,
    ],
    "weight" => [
        "kg" => 1.0,
        "g" => 1000.0,
        "lb" => 2.20462,
        "oz" => 35.274,
        "mg" => 1000000.0,
    ],
    "temperature" => [
        "C" => "celsius",
        "F" => "fahrenheit",
        "K" => "kelvin",
    ],
];

$GLOBALS['CATEGORY_UNITS'] = [
    "length" => ["m", "km", "mi", "ft", "in", "cm"],
    "weight" => ["kg", "g", "lb", "oz", "mg"],
    "temperature" => ["C", "F", "K"],
];

function list_categories() {
    global $CONVERSION;
    return array_keys($CONVERSION);
}

function convert_temperature($value, $from_unit, $to_unit) {
    if ($from_unit === $to_unit) return $value;
    if ($from_unit === "C") {
        if ($to_unit === "F") return $value * 9.0 / 5.0 + 32;
        if ($to_unit === "K") return $value + 273.15;
    }
    if ($from_unit === "F") {
        if ($to_unit === "C") return ($value - 32) * 5.0 / 9.0;
        if ($to_unit === "K") return ($value - 32) * 5.0 / 9.0 + 273.15;
    }
    if ($from_unit === "K") {
        if ($to_unit === "C") return $value - 273.15;
        if ($to_unit === "F") return ($value - 273.15) * 9.0 / 5.0 + 32;
    }
    throw new InvalidArgumentException("Invalid temperature conversion: $from_unit -> $to_unit");
}

function convert($value, $from_unit, $to_unit) {
    global $CONVERSION;
    foreach ($CONVERSION as $category => $units) {
        if (isset($units[$from_unit]) && isset($units[$to_unit])) {
            if ($category === "temperature") {
                return convert_temperature($value, $from_unit, $to_unit);
            }
            $factor_from = $units[$from_unit];
            $factor_to = $units[$to_unit];
            return $value / $factor_from * $factor_to;
        }
    }
    throw new InvalidArgumentException("Incompatible units: $from_unit -> $to_unit");
}

function main() {
    echo "=== Unit Converter ===\n";
    while (true) {
        echo "\nCategories:\n";
        $cats = list_categories();
        foreach ($cats as $i => $cat) {
            echo "  " . ($i + 1) . ". $cat\n";
        }
        echo "  0. Exit\n";
        echo "Select category: ";
        $line = trim(fgets(STDIN));
        if ($line === "0") {
            echo "Goodbye!\n";
            break;
        }
        $idx = (int)$line - 1;
        if (!isset($cats[$idx])) {
            echo "Invalid choice\n";
            continue;
        }
        $category = $cats[$idx];

        global $CATEGORY_UNITS;
        $units = $CATEGORY_UNITS[$category];
        echo "\nUnits ($category):\n";
        foreach ($units as $i => $u) {
            echo "  " . ($i + 1) . ". $u\n";
        }

        echo "Select from unit: ";
        $from_idx = (int)trim(fgets(STDIN)) - 1;
        echo "Select to unit: ";
        $to_idx = (int)trim(fgets(STDIN)) - 1;
        if (!isset($units[$from_idx]) || !isset($units[$to_idx])) {
            echo "Invalid unit selection\n";
            continue;
        }
        echo "Enter value: ";
        $value = (float)trim(fgets(STDIN));
        try {
            $result = convert($value, $units[$from_idx], $units[$to_idx]);
            echo "\nResult: $value {$units[$from_idx]} = $result {$units[$to_idx]}\n";
        } catch (Exception $e) {
            echo "Error: " . $e->getMessage() . "\n";
        }
    }
}

if (PHP_SAPI === 'cli' && isset($argv[0]) && realpath($argv[0]) === __FILE__) {
    main();
}
