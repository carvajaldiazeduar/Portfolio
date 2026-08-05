<?php

function generate_password(int $length = 16, bool $use_upper = true, bool $use_lower = true, bool $use_digits = true, bool $use_symbols = true): string {
    if ($length < 1) {
        throw new InvalidArgumentException("Password length must be at least 1");
    }

    $upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    $lower = "abcdefghijklmnopqrstuvwxyz";
    $digits = "0123456789";
    $symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?";

    $categories = [];
    if ($use_upper) $categories[] = $upper;
    if ($use_lower) $categories[] = $lower;
    if ($use_digits) $categories[] = $digits;
    if ($use_symbols) $categories[] = $symbols;

    if (empty($categories)) {
        throw new InvalidArgumentException("At least one character category must be enabled");
    }

    if ($length < count($categories)) {
        throw new InvalidArgumentException(
            "Password length must be at least " . count($categories) .
            " when " . count($categories) . " categories are enabled"
        );
    }

    $password = "";
    foreach ($categories as $cat) {
        $password .= $cat[random_int(0, strlen($cat) - 1)];
    }

    $all_chars = implode("", $categories);
    $remaining = $length - count($categories);
    for ($i = 0; $i < $remaining; $i++) {
        $password .= $all_chars[random_int(0, strlen($all_chars) - 1)];
    }

    $password = str_split($password);
    shuffle($password);
    return implode("", $password);
}

function show_menu(): void {
    echo "=== Password Generator ===\n";
    echo "Length (default 16): ";
    $input = trim(fgets(STDIN));
    $length = $input === "" ? 16 : (int)$input;

    echo "Include uppercase? (Y/n): ";
    $use_upper = strtolower(trim(fgets(STDIN))) !== "n";

    echo "Include lowercase? (Y/n): ";
    $use_lower = strtolower(trim(fgets(STDIN))) !== "n";

    echo "Include digits? (Y/n): ";
    $use_digits = strtolower(trim(fgets(STDIN))) !== "n";

    echo "Include symbols? (Y/n): ";
    $use_symbols = strtolower(trim(fgets(STDIN))) !== "n";

    try {
        $password = generate_password($length, $use_upper, $use_lower, $use_digits, $use_symbols);
        echo "\nGenerated password: $password\n";
    } catch (InvalidArgumentException $e) {
        echo "Error: " . $e->getMessage() . "\n";
    }
}

if (PHP_SAPI === "cli" && isset($argv[0]) && realpath($argv[0]) === __FILE__) {
    if ($argc > 1) {
        $opts = getopt("l:", ["no-upper", "no-lower", "no-digits", "no-symbols", "length:"]);
        $length = isset($opts["l"]) ? (int)$opts["l"] : (isset($opts["length"]) ? (int)$opts["length"] : 16);
        $use_upper = !isset($opts["no-upper"]);
        $use_lower = !isset($opts["no-lower"]);
        $use_digits = !isset($opts["no-digits"]);
        $use_symbols = !isset($opts["no-symbols"]);
        try {
            echo generate_password($length, $use_upper, $use_lower, $use_digits, $use_symbols) . "\n";
        } catch (InvalidArgumentException $e) {
            fwrite(STDERR, "Error: " . $e->getMessage() . "\n");
            exit(1);
        }
    } else {
        show_menu();
    }
}
