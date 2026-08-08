<?php

require_once __DIR__ . '/../tasks.php';

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

test('addTask', function () {
    $tasks = [];
    $id = add_task($tasks, 'Test', 'A task');
    assert($id === 1);
    assert(count($tasks) === 1);
    assert($tasks[0]['title'] === 'Test');
    assert($tasks[0]['description'] === 'A task');
    assert($tasks[0]['completed'] === false);
    assert(array_key_exists('created_at', $tasks[0]));
});

test('addTaskAutoIncrement', function () {
    $tasks = [
        ['id' => 1, 'title' => 'a', 'description' => '', 'completed' => false, 'created_at' => '']
    ];
    $id = add_task($tasks, 'b', '');
    assert($id === 2);
});

test('listTasksNoTasks', function () {
    ob_start();
    list_tasks([]);
    $output = ob_get_clean();
    assert($output === "No tasks found.\n");
});

test('listTasks', function () {
    $tasks = [
        ['id' => 1, 'title' => 'Buy milk', 'description' => '', 'completed' => false, 'created_at' => 'now']
    ];
    ob_start();
    list_tasks($tasks);
    $output = ob_get_clean();
    assert(preg_match('/\[ \].*Buy milk/', $output) === 1);
});

test('listTasksCompleted', function () {
    $tasks = [
        ['id' => 1, 'title' => 'Done', 'description' => '', 'completed' => true, 'created_at' => 'now']
    ];
    ob_start();
    list_tasks($tasks);
    $output = ob_get_clean();
    assert(preg_match('/\[x\].*Done/', $output) === 1);
});

test('completeTask', function () {
    $tasks = [
        ['id' => 1, 'title' => 'a', 'description' => '', 'completed' => false, 'created_at' => '']
    ];
    $result = complete_task($tasks, 1);
    assert($result === true);
    assert($tasks[0]['completed'] === true);
});

test('completeTaskNotFound', function () {
    $tasks = [];
    $result = complete_task($tasks, 99);
    assert($result === false);
});

test('deleteTask', function () {
    $tasks = [
        ['id' => 1, 'title' => 'a', 'description' => '', 'completed' => false, 'created_at' => '']
    ];
    $result = delete_task($tasks, 1);
    assert($result === true);
    assert(count($tasks) === 0);
});

test('deleteTaskNotFound', function () {
    $tasks = [
        ['id' => 1, 'title' => 'a', 'description' => '', 'completed' => false, 'created_at' => '']
    ];
    $result = delete_task($tasks, 99);
    assert($result === false);
    assert(count($tasks) === 1);
});

if ($fail > 0) {
    fwrite(STDERR, "{$fail} test(s) failed\n");
    exit(1);
}
echo "OK: {$pass} tests passed\n";
