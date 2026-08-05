<?php

use PHPUnit\Framework\TestCase;

class TasksApiTest extends TestCase
{
    private string $baseUrl = 'http://localhost:8000';

    /**
    * Start the PHP built-in server for testing.
    * Run: php -S localhost:8000 index.php
    * Then run: phpunit Tests/TasksApiTest.php
    */
    protected function setUp(): void
    {
        // Ensure the server is running before tests
        // This test file assumes the server is already started manually.
        // In CI you could use:
        // exec('php -S localhost:8000 ' . __DIR__ . '/../index.php > /dev/null 2>&1 &');
    }

    public function testGetTasksEmpty(): void
    {
        $resp = file_get_contents($this->baseUrl . '/api/tasks');
        $this->assertNotFalse($resp);
        $data = json_decode($resp, true);
        $this->assertIsArray($data);
    }

    public function testAddTask(): void
    {
        $ctx = stream_context_create([
            'http' => [
                'method' => 'POST',
                'header'  => "Content-Type: application/json\r\n",
                'content' => json_encode(['title' => 'Test', 'description' => 'Desc']),
                'ignore_errors' => true,
            ]
        ]);
        $resp = file_get_contents($this->baseUrl . '/api/tasks', false, $ctx);
        $this->assertNotFalse($resp);
        $data = json_decode($resp, true);
        $this->assertArrayHasKey('title', $data);
        $this->assertSame('Test', $data['title']);
    }

    public function testCompleteTaskNotFound(): void
    {
        $ctx = stream_context_create([
            'http' => [
                'method' => 'PUT',
                'ignore_errors' => true,
            ]
        ]);
        $resp = @file_get_contents($this->baseUrl . '/api/tasks/999/complete', false, $ctx);
        // 404 expected
        $this->assertFalse($resp);
    }

    public function testDeleteTaskNotFound(): void
    {
        $ctx = stream_context_create([
            'http' => [
                'method' => 'DELETE',
                'ignore_errors' => true,
            ]
        ]);
        $resp = @file_get_contents($this->baseUrl . '/api/tasks/999', false, $ctx);
        $this->assertFalse($resp);
    }
}

