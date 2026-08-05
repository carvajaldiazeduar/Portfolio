<?php
require_once __DIR__ . '/../index.php';

use PHPUnit\Framework\TestCase;

class ConversorApiTest extends TestCase
{
    public function testCategoriesEndpoint()
    {
        $data = json_decode(file_get_contents('php://input'), true);
        global $CATEGORY_UNITS;
        $this->assertArrayHasKey('length', $CATEGORY_UNITS);
        $this->assertArrayHasKey('weight', $CATEGORY_UNITS);
        $this->assertArrayHasKey('temperature', $CATEGORY_UNITS);
    }

    public function testConvertLength()
    {
        $result = convert(1, "m", "cm");
        $this->assertEqualsWithDelta(100, $result, 0.001);
    }

    public function testConvertInvalid()
    {
        $this->expectException(InvalidArgumentException::class);
        convert(1, "m", "kg");
    }
}
