<?php

function add(float $a, float $b): float {
    return $a + $b;
}

function subtract(float $a, float $b): float {
    return $a - $b;
}

function multiply(float $a, float $b): float {
    return $a * $b;
}

function divide(float $a, float $b): float|string {
    if ($b == 0) {
        return "Error: Cannot divide by zero";
    }
    return $a / $b;
}

function showMenu(): void {
    echo "\n=== Simple Calculator ===\n";
    echo "1. Add\n";
    echo "2. Subtract\n";
    echo "3. Multiply\n";
    echo "4. Divide\n";
    echo "5. Exit\n";
}

function getNumber(string $prompt): float {
    while (true) {
        echo $prompt;
        $input = trim(fgets(STDIN));
        if (is_numeric($input)) {
            return (float) $input;
        }
        echo "Invalid input. Please enter a number.\n";
    }
}

function main(): void {
    $operations = [
        "1" => ["add", "add", "+"],
        "2" => ["subtract", "subtract", "-"],
        "3" => ["multiply", "multiply", "*"],
        "4" => ["divide", "divide", "/"],
    ];

    while (true) {
        showMenu();
        echo "Choose an option (1-5): ";
        $choice = trim(fgets(STDIN));

        if ($choice === "5") {
            echo "Goodbye!\n";
            break;
        }

        if (!isset($operations[$choice])) {
            echo "Invalid option. Please try again.\n";
            continue;
        }

        $num1 = getNumber("Enter first number: ");
        $num2 = getNumber("Enter second number: ");

        [$_, $func, $operation] = $operations[$choice];
        $result = $func($num1, $num2);

        echo "\n{$num1} {$operation} {$num2} = {$result}\n";
    }
}

if (PHP_SAPI === "cli" && isset($argv[0]) && realpath($argv[0]) === __FILE__) {
    main();
}
