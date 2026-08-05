<?php

$messages = [];
$nextId = 1;

function sendMessage(string $from, string $subject, string $body): array
{
    global $messages, $nextId;
    $msg = [
        "id" => $nextId,
        "from" => $from,
        "subject" => $subject,
        "body" => $body,
        "read" => false,
        "created_at" => date("c"),
    ];
    $messages[] = $msg;
    $nextId++;
    return $msg;
}

function listMessages(): array
{
    global $messages;
    return $messages;
}

function readMessage(int $id): ?array
{
    global $messages;
    foreach ($messages as &$m) {
        if ($m["id"] === $id) {
            $m["read"] = true;
            return $m;
        }
    }
    return null;
}

function deleteMessage(int $id): bool
{
    global $messages;
    foreach ($messages as $i => $m) {
        if ($m["id"] === $id) {
            array_splice($messages, $i, 1);
            return true;
        }
    }
    return false;
}

function main(): void
{
    while (true) {
        echo "\n=== Inbox CLI ===\n";
        echo "1. Send message\n";
        echo "2. List messages\n";
        echo "3. Read message\n";
        echo "4. Delete message\n";
        echo "5. Exit\n";
        echo "Choice: ";
        $choice = trim(fgets(STDIN));

        if ($choice === "1") {
            echo "From: ";
            $from = trim(fgets(STDIN));
            echo "Subject: ";
            $subject = trim(fgets(STDIN));
            echo "Body: ";
            $body = trim(fgets(STDIN));
            $msg = sendMessage($from, $subject, $body);
            echo "Message sent (id={$msg['id']})\n";
        } elseif ($choice === "2") {
            $msgs = listMessages();
            if (empty($msgs)) {
                echo "No messages.\n";
            } else {
                foreach ($msgs as $m) {
                    $status = $m["read"] ? "✓" : "✗";
                    echo "[{$m['id']}] {$status} From: {$m['from']} | Subject: {$m['subject']} | {$m['created_at']}\n";
                }
            }
        } elseif ($choice === "3") {
            echo "Message ID: ";
            $id = (int) trim(fgets(STDIN));
            $msg = readMessage($id);
            if ($msg) {
                echo "From: {$msg['from']}\n";
                echo "Subject: {$msg['subject']}\n";
                echo "Date: {$msg['created_at']}\n";
                echo "---\n{$msg['body']}\n";
            } else {
                echo "Message not found.\n";
            }
        } elseif ($choice === "4") {
            echo "Message ID: ";
            $id = (int) trim(fgets(STDIN));
            if (deleteMessage($id)) {
                echo "Message deleted.\n";
            } else {
                echo "Message not found.\n";
            }
        } elseif ($choice === "5") {
            break;
        }
    }
}

if (PHP_SAPI === "cli" && isset($argv[0]) && realpath($argv[0]) === __FILE__) {
    main();
}
