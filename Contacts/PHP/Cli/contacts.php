<?php

function validateContact(string $name, string $phone, string $email): array {
    $errors = [];
    $name = trim($name);
    $phone = trim($phone);
    $email = trim($email);
    if ($name === '') {
        $errors['name'] = 'Name is required';
    } elseif (strlen($name) < 2 || strlen($name) > 100 || !preg_match('/^[A-Za-zÀ-ÿ\' .-]+$/', $name)) {
        $errors['name'] = 'Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)';
    }
    if ($phone === '') {
        $errors['phone'] = 'Phone is required';
    } elseif (!preg_match('/^[0-9 +().-]{7,20}$/', $phone)) {
        $errors['phone'] = 'Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)';
    }
    if ($email === '') {
        $errors['email'] = 'Email is required';
    } elseif (!preg_match('/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/', $email)) {
        $errors['email'] = 'Invalid email format';
    }
    return $errors;
}

function addContact(array &$contacts, string $name, string $phone, string $email): void {
    $errors = validateContact($name, $phone, $email);
    if ($errors) {
        foreach ($errors as $error) {
            fwrite(STDERR, $error . "\n");
        }
        return;
    }
    $contacts[] = ["name" => trim($name), "phone" => trim($phone), "email" => trim($email)];
    echo "Contact added!\n";
}

function listContacts(array $contacts): void {
    if (empty($contacts)) {
        echo "No contacts found.\n";
        return;
    }
    foreach ($contacts as $i => $c) {
        echo "$i. {$c['name']} | {$c['phone']} | {$c['email']}\n";
    }
}

function searchContacts(array $contacts, string $query): array {
    $results = [];
    foreach ($contacts as $c) {
        if (stripos($c['name'], $query) !== false) {
            $results[] = $c;
        }
    }
    if (empty($results)) {
        echo "No contacts found.\n";
    } else {
        foreach ($results as $i => $c) {
            echo "$i. {$c['name']} | {$c['phone']} | {$c['email']}\n";
        }
    }
    return $results;
}

function deleteContact(array &$contacts, int $index): void {
    if (isset($contacts[$index])) {
        $removed = $contacts[$index];
        array_splice($contacts, $index, 1);
        echo "Deleted {$removed['name']}\n";
    } else {
        echo "Invalid index.\n";
    }
}

function main(): void {
    $contacts = [];
    while (true) {
        echo "\n--- Contact Manager ---\n";
        echo "1. Add Contact\n";
        echo "2. List Contacts\n";
        echo "3. Search Contacts\n";
        echo "4. Delete Contact\n";
        echo "5. Exit\n";
        echo "Choose an option: ";
        $choice = trim(fgets(STDIN));
        switch ($choice) {
            case '1':
                echo "Name: ";
                $name = trim(fgets(STDIN));
                echo "Phone: ";
                $phone = trim(fgets(STDIN));
                echo "Email: ";
                $email = trim(fgets(STDIN));
                addContact($contacts, $name, $phone, $email);
                break;
            case '2':
                listContacts($contacts);
                break;
            case '3':
                echo "Search query: ";
                $query = trim(fgets(STDIN));
                searchContacts($contacts, $query);
                break;
            case '4':
                listContacts($contacts);
                echo "Enter index to delete: ";
                $idx = (int) trim(fgets(STDIN));
                deleteContact($contacts, $idx);
                break;
            case '5':
                echo "Goodbye!\n";
                exit(0);
        }
    }
}

if (PHP_SAPI === 'cli' && isset($argv[0]) && realpath($argv[0]) === __FILE__) {
    main();
}
