<?php
require_once __DIR__ . '/../conversor.php';

use PHPUnit\Framework\TestCase;

class ConversorTest extends TestCase
{
    public function testLengthConversion()
    {
        $result = convert(1, "m", "cm");
        $this->assertEqualsWithDelta(100, $result, 0.001);
    }

    public function testWeightConversion()
    {
        $result = convert(1, "kg", "g");
        $this->assertEqualsWithDelta(1000, $result, 0.001);
    }

    public function testTemperatureCtoF()
    {
        $result = convert(0, "C", "F");
        $this->assertEqualsWithDelta(32, $result, 0.001);
    }

    public function testTemperatureCtoK()
    {
        $result = convert(0, "C", "K");
        $this->assertEqualsWithDelta(273.15, $result, 0.001);
    }

    public function testTemperatureFtoC()
    {
        $result = convert(32, "F", "C");
        $this->assertEqualsWithDelta(0, $result, 0.001);
    }

    public function testTemperatureFtoK()
    {
        $result = convert(32, "F", "K");
        $this->assertEqualsWithDelta(273.15, $result, 0.001);
    }

    public function testTemperatureKtoC()
    {
        $result = convert(273.15, "K", "C");
        $this->assertEqualsWithDelta(0, $result, 0.001);
    }

    public function testTemperatureKtoF()
    {
        $result = convert(273.15, "K", "F");
        $this->assertEqualsWithDelta(32, $result, 0.001);
    }

    public function testInvalidUnit()
    {
        $this->expectException(InvalidArgumentException::class);
        convert(1, "m", "kg");
    }

    public function testIncompatibleCategories()
    {
        $this->expectException(InvalidArgumentException::class);
        convert(1, "m", "kg");
    }

    public function testListCategories()
    {
        $cats = list_categories();
        $this->assertContains("length", $cats);
        $this->assertContains("weight", $cats);
        $this->assertContains("temperature", $cats);
    }

    public function testKmToMi()
    {
        $result = convert(1, "km", "mi");
        $this->assertEqualsWithDelta(0.621371, $result, 0.001);
    }

    public function testLbToOz()
    {
        $result = convert(1, "lb", "oz");
        $this->assertEqualsWithDelta(16, $result, 0.001);
    }

    public function testIdentity()
    {
        $result = convert(100, "cm", "cm");
        $this->assertEqualsWithDelta(100, $result, 0.001);
    }
}
