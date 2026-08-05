<?php

require_once __DIR__ . "/../index.php";

use PHPUnit\Framework\TestCase;

class CalculatorApiTest extends TestCase
{
    private function getBaseUrl(): string
    {
        return "http://localhost:8000";
    }

    public function testCalculateAdd()
    {
        $data = json_encode(["a" => 2, "b" => 3, "operator" => "add"]);
        $context = stream_context_create([
            "http" => [
                "method" => "POST",
                "header" => "Content-Type: application/json",
                "content" => $data,
            ],
        ]);
        $result = file_get_contents($this->getBaseUrl(), false, $context);
        $response = json_decode($result, true);
        $this->assertEquals(5, $response["result"]);
    }
}
