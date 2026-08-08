<?php

require_once __DIR__ . '/../inboxes.php';

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

function resetInbox(): void {
    global $messages, $nextId;
    $messages = [];
    $nextId = 1;
}

test('sendMessage', function () {
    resetInbox();
    $msg = sendMessage("alice", "Hello", "World");
    assert($msg["id"] === 1);
    assert($msg["from"] === "alice");
    assert($msg["subject"] === "Hello");
    assert($msg["body"] === "World");
    assert($msg["read"] === false);
    assert($msg["created_at"] !== null);
});

test('listMessages', function () {
    resetInbox();
    sendMessage("alice", "Subject1", "Body1");
    sendMessage("bob", "Subject2", "Body2");
    $msgs = listMessages();
    assert(count($msgs) === 2);
});

test('readMessageMarksAsRead', function () {
    resetInbox();
    sendMessage("alice", "Test", "Body");
    $msg = readMessage(1);
    assert($msg !== null);
    assert($msg["read"] === true);
    $msg2 = readMessage(1);
    assert($msg2["read"] === true);
});

test('deleteMessage', function () {
    resetInbox();
    sendMessage("alice", "Del", "Me");
    assert(count(listMessages()) === 1);
    assert(deleteMessage(1) === true);
    assert(count(listMessages()) === 0);
});

test('listAfterDelete', function () {
    resetInbox();
    sendMessage("alice", "Keep", "Me");
    sendMessage("bob", "Delete", "This");
    deleteMessage(2);
    $msgs = listMessages();
    assert(count($msgs) === 1);
    assert($msgs[0]["id"] === 1);
});

test('readNonexistent', function () {
    resetInbox();
    assert(readMessage(999) === null);
});

test('deleteNonexistent', function () {
    resetInbox();
    assert(deleteMessage(999) === false);
});

if ($fail > 0) {
    fwrite(STDERR, "{$fail} test(s) failed\n");
    exit(1);
}
echo "OK: {$pass} tests passed\n";
