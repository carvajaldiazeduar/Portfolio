<?php

require_once __DIR__ . "/../calculator.php";

use PHPUnit\Framework\TestCase;

class CalculatorTest extends TestCase
{
    public function testAdd()
    {
        $this->assertEquals(5, add(2, 3));
        $this->assertEquals(0, add(-1, 1));
        $this->assertEquals(0, add(0, 0));
    }

    public function testSubtract()
    {
        $this->assertEquals(2, subtract(5, 3));
        $this->assertEquals(-5, subtract(0, 5));
        $this->assertEquals(0, subtract(-1, -1));
    }

    public function testMultiply()
    {
        $this->assertEquals(6, multiply(2, 3));
        $this->assertEquals(0, multiply(0, 5));
        $this->assertEquals(-6, multiply(-2, 3));
    }

    public function testDivide()
    {
        $this->assertEquals(2, divide(6, 3));
        $this->assertEquals(2.5, divide(5, 2));
        $this->assertEquals(0, divide(0, 5));
    }

    public function testDivideByZero()
    {
        $this->assertEquals("Error: Cannot divide by zero", divide(5, 0));
    }
}
