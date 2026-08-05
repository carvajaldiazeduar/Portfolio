<?php

use PHPUnit\Framework\TestCase;

class InboxesApiTest extends TestCase
{
    private string $baseUrl = "http://localhost:8000";

    /**
    * Start PHP built-in server for testing.
    * Run: php -S localhost:8000 -t ../ index.php
    * Then run: phpunit InboxesApiTest.php
    */
    public function testListEmpty(): void
    {
        $res = file_get_contents($this->baseUrl . "/api/messages");
        $this->assertNotFalse($res);
        $data = json_decode($res, true);
        $this->assertIsArray($data);
    }

    public function testSendAndList(): void
    {
        $ctx = stream_context_create([
            "http" => [
                "method" => "POST",
                "header" => "Content-Type: application/json",
                "content" => json_encode(["from" => "alice", "subject" => "Hello", "body" => "World"]),
                "ignore_errors" => true,
            ],
        ]);
        $res = file_get_contents($this->baseUrl . "/api/messages", false, $ctx);
        $this->assertNotFalse($res);
        $data = json_decode($res, true);
        $this->assertEquals(1, $data["id"]);
        $this->assertEquals("alice", $data["from"]);
    }
}

