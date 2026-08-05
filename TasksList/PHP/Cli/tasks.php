<?php

function add_task(array &$tasks, string $title, string $description): int
{
    $id = empty($tasks) ? 1 : max(array_column($tasks, 'id')) + 1;
    $tasks[] = [
        'id' => $id,
        'title' => $title,
        'description' => $description,
        'completed' => false,
        'created_at' => date('c'),
    ];
    return $id;
}

function list_tasks(array $tasks): void
{
    if (empty($tasks)) {
        echo "No tasks found.\n";
        return;
    }
    foreach ($tasks as $t) {
        $status = $t['completed'] ? '[x]' : '[ ]';
        echo "{$status} {$t['id']}. {$t['title']} — {$t['created_at']}\n";
    }
}

function complete_task(array &$tasks, int $id): bool
{
    foreach ($tasks as &$t) {
        if ($t['id'] === $id) {
            $t['completed'] = true;
            return true;
        }
    }
    return false;
}

function delete_task(array &$tasks, int $id): bool
{
    foreach ($tasks as $i => $t) {
        if ($t['id'] === $id) {
            array_splice($tasks, $i, 1);
            return true;
        }
    }
    return false;
}

function main(): void
{
    $tasks = [];
    while (true) {
        echo "\n=== Tasks List ===\n";
        echo "1. Add Task\n";
        echo "2. List Tasks\n";
        echo "3. Complete Task\n";
        echo "4. Delete Task\n";
        echo "5. Exit\n";
        echo "Choose an option: ";
        $choice = trim(fgets(STDIN));

        switch ($choice) {
            case '1':
                echo "Title: ";
                $title = trim(fgets(STDIN));
                echo "Description: ";
                $description = trim(fgets(STDIN));
                add_task($tasks, $title, $description);
                echo "Task added.\n";
                break;
            case '2':
                list_tasks($tasks);
                break;
            case '3':
                echo "Task ID to complete: ";
                $id = (int) trim(fgets(STDIN));
                if (complete_task($tasks, $id)) {
                    echo "Task completed.\n";
                } else {
                    echo "Task not found.\n";
                }
                break;
            case '4':
                echo "Task ID to delete: ";
                $id = (int) trim(fgets(STDIN));
                if (delete_task($tasks, $id)) {
                    echo "Task deleted.\n";
                } else {
                    echo "Task not found.\n";
                }
                break;
            case '5':
                echo "Goodbye!\n";
                exit;
            default:
                echo "Invalid option.\n";
        }
    }
}

if (PHP_SAPI === 'cli' && isset($argv[0]) && realpath($argv[0]) === __FILE__) {
    main();
}
