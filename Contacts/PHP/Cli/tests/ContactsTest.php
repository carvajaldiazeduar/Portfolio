<?php

require_once __DIR__ . '/../contacts.php';

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

test('addContact', function () {
    $contacts = [];
    addContact($contacts, "Alice", "123-4567", "alice@test.com");
    assert(count($contacts) === 1);
    assert($contacts[0]["name"] === "Alice");
    assert($contacts[0]["phone"] === "123-4567");
    assert($contacts[0]["email"] === "alice@test.com");
});

test('addContactInvalidEmail', function () {
    $contacts = [];
    addContact($contacts, "Alice", "123-4567", "not-an-email");
    assert(count($contacts) === 0);
});

test('addContactInvalidPhone', function () {
    $contacts = [];
    addContact($contacts, "Alice", "abc", "alice@test.com");
    assert(count($contacts) === 0);
});

test('addContactMissingName', function () {
    $contacts = [];
    addContact($contacts, "   ", "123-4567", "alice@test.com");
    assert(count($contacts) === 0);
});

test('addContactNameTooShort', function () {
    $contacts = [];
    addContact($contacts, "A", "123-4567", "alice@test.com");
    assert(count($contacts) === 0);
});

test('validateContactErrors', function () {
    $errors = validateContact("", "abc", "bad");
    assert($errors["name"] === "Name is required");
    assert($errors["phone"] === "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)");
    assert($errors["email"] === "Invalid email format");
});

test('searchContactsFound', function () {
    $contacts = [
        ["name" => "Alice", "phone" => "123", "email" => "a@b.com"],
        ["name" => "Bob", "phone" => "456", "email" => "b@c.com"],
        ["name" => "Alexander", "phone" => "789", "email" => "alex@d.com"]
    ];
    $results = searchContacts($contacts, "al");
    assert(count($results) === 2);
});

test('searchContactsNotFound', function () {
    $contacts = [
        ["name" => "Alice", "phone" => "123", "email" => "a@b.com"]
    ];
    ob_start();
    $results = searchContacts($contacts, "zzz");
    $output = ob_get_clean();
    assert(count($results) === 0);
    assert(strpos($output, 'No contacts') !== false);
});

test('deleteContactValid', function () {
    $contacts = [
        ["name" => "Alice", "phone" => "123", "email" => "a@b.com"],
        ["name" => "Bob", "phone" => "456", "email" => "b@c.com"]
    ];
    deleteContact($contacts, 0);
    assert(count($contacts) === 1);
    assert($contacts[0]["name"] === "Bob");
});

test('deleteContactInvalid', function () {
    $contacts = [
        ["name" => "Alice", "phone" => "123", "email" => "a@b.com"]
    ];
    ob_start();
    deleteContact($contacts, 5);
    $output = ob_get_clean();
    assert(count($contacts) === 1);
    assert(strpos($output, 'Invalid') !== false);
});

test('listContactsEmpty', function () {
    ob_start();
    listContacts([]);
    $output = ob_get_clean();
    assert(strpos($output, 'No contacts') !== false);
});

if ($fail > 0) {
    fwrite(STDERR, "{$fail} test(s) failed\n");
    exit(1);
}
echo "OK: {$pass} tests passed\n";
