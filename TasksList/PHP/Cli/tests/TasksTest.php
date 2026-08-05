<?php

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../tasks.php';

class TasksTest extends TestCase
{
    public function testAddTask(): void
    {
        $tasks = [];
        $id = add_task($tasks, 'Test', 'A task');
        $this->assertSame(1, $id);
        $this->assertCount(1, $tasks);
        $this->assertSame('Test', $tasks[0]['title']);
        $this->assertSame('A task', $tasks[0]['description']);
        $this->assertFalse($tasks[0]['completed']);
        $this->assertArrayHasKey('created_at', $tasks[0]);
    }

    public function testAddTaskAutoIncrement(): void
    {
        $tasks = [
            ['id' => 1, 'title' => 'a', 'description' => '', 'completed' => false, 'created_at' => '']
        ];
        $id = add_task($tasks, 'b', '');
        $this->assertSame(2, $id);
    }

    public function testListTasksNoTasks(): void
    {
        $this->expectOutputString("No tasks found.\n");
        list_tasks([]);
    }

    public function testListTasks(): void
    {
        $tasks = [
            ['id' => 1, 'title' => 'Buy milk', 'description' => '', 'completed' => false, 'created_at' => 'now']
        ];
        $this->expectOutputRegex('/\[ \].*Buy milk/');
        list_tasks($tasks);
    }

    public function testListTasksCompleted(): void
    {
        $tasks = [
            ['id' => 1, 'title' => 'Done', 'description' => '', 'completed' => true, 'created_at' => 'now']
        ];
        $this->expectOutputRegex('/\[x\].*Done/');
        list_tasks($tasks);
    }

    public function testCompleteTask(): void
    {
        $tasks = [
            ['id' => 1, 'title' => 'a', 'description' => '', 'completed' => false, 'created_at' => '']
        ];
        $result = complete_task($tasks, 1);
        $this->assertTrue($result);
        $this->assertTrue($tasks[0]['completed']);
    }

    public function testCompleteTaskNotFound(): void
    {
        $tasks = [];
        $result = complete_task($tasks, 99);
        $this->assertFalse($result);
    }

    public function testDeleteTask(): void
    {
        $tasks = [
            ['id' => 1, 'title' => 'a', 'description' => '', 'completed' => false, 'created_at' => '']
        ];
        $result = delete_task($tasks, 1);
        $this->assertTrue($result);
        $this->assertCount(0, $tasks);
    }

    public function testDeleteTaskNotFound(): void
    {
        $tasks = [
            ['id' => 1, 'title' => 'a', 'description' => '', 'completed' => false, 'created_at' => '']
        ];
        $result = delete_task($tasks, 99);
        $this->assertFalse($result);
        $this->assertCount(1, $tasks);
    }
}
