<?php
require_once __DIR__ . "/../index.php";

use PHPUnit\Framework\TestCase;

class PasswordGeneratorApiTest extends TestCase {
    public function testGenerateDefault() {
        $pw = generate_password();
        $this->assertEquals(16, strlen($pw));
    }

    public function testGenerateCustomLength() {
        $pw = generate_password(24);
        $this->assertEquals(24, strlen($pw));
    }

    public function testGenerateNoUppercase() {
        $pw = generate_password(16, false);
        $this->assertDoesNotMatchRegularExpression('/[A-Z]/', $pw);
    }

    public function testGenerateNoSymbols() {
        $pw = generate_password(16, true, true, true, false);
        $this->assertDoesNotMatchRegularExpression('/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', $pw);
    }

    public function testGenerateAllDisabledThrows() {
        $this->expectException(InvalidArgumentException::class);
        generate_password(10, false, false, false, false);
    }

    public function testGenerateNegativeLengthThrows() {
        $this->expectException(InvalidArgumentException::class);
        generate_password(-1);
    }

    public function testGenerateAtLeastOneFromEach() {
        $pw = generate_password(20, true, true, true, true);
        $this->assertMatchesRegularExpression('/[A-Z]/', $pw);
        $this->assertMatchesRegularExpression('/[a-z]/', $pw);
        $this->assertMatchesRegularExpression('/[0-9]/', $pw);
        $this->assertMatchesRegularExpression('/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', $pw);
    }
}
