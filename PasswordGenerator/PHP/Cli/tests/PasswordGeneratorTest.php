<?php
require_once __DIR__ . "/../password_generator.php";

use PHPUnit\Framework\TestCase;

class PasswordGeneratorTest extends TestCase {
    public function testDefaultLength() {
        $pw = generate_password();
        $this->assertEquals(16, strlen($pw));
    }

    public function testCustomLength() {
        $pw = generate_password(24);
        $this->assertEquals(24, strlen($pw));
    }

    public function testMinLength() {
        $pw = generate_password(1, true, false, false, false);
        $this->assertEquals(1, strlen($pw));
    }

    public function testUppercasePresent() {
        $pw = generate_password(10, true, false, false, false);
        $this->assertMatchesRegularExpression('/[A-Z]/', $pw);
    }

    public function testLowercasePresent() {
        $pw = generate_password(10, false, true, false, false);
        $this->assertMatchesRegularExpression('/[a-z]/', $pw);
    }

    public function testDigitsPresent() {
        $pw = generate_password(10, false, false, true, false);
        $this->assertMatchesRegularExpression('/[0-9]/', $pw);
    }

    public function testSymbolsPresent() {
        $pw = generate_password(10, false, false, false, true);
        $this->assertMatchesRegularExpression('/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', $pw);
    }

    public function testNoUppercase() {
        $pw = generate_password(16, false);
        $this->assertDoesNotMatchRegularExpression('/[A-Z]/', $pw);
    }

    public function testNoSymbols() {
        $pw = generate_password(16, true, true, true, false);
        $this->assertDoesNotMatchRegularExpression('/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', $pw);
    }

    public function testNoLowercase() {
        $pw = generate_password(16, false, false);
        $this->assertDoesNotMatchRegularExpression('/[a-z]/', $pw);
    }

    public function testNoDigits() {
        $pw = generate_password(16, false, false, false);
        $this->assertDoesNotMatchRegularExpression('/[0-9]/', $pw);
    }

    public function testAllDisabledThrows() {
        $this->expectException(InvalidArgumentException::class);
        generate_password(10, false, false, false, false);
    }

    public function testLengthZeroThrows() {
        $this->expectException(InvalidArgumentException::class);
        generate_password(0);
    }

    public function testNegativeLengthThrows() {
        $this->expectException(InvalidArgumentException::class);
        generate_password(-5);
    }

    public function testLengthTooShortForCategories() {
        $this->expectException(InvalidArgumentException::class);
        generate_password(2, true, true, true, true);
    }

    public function testAtLeastOneFromEachEnabled() {
        $pw = generate_password(20, true, true, true, true);
        $this->assertMatchesRegularExpression('/[A-Z]/', $pw);
        $this->assertMatchesRegularExpression('/[a-z]/', $pw);
        $this->assertMatchesRegularExpression('/[0-9]/', $pw);
        $this->assertMatchesRegularExpression('/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', $pw);
    }

    public function testOnlyUppercaseAndDigits() {
        $pw = generate_password(12, true, false, true, false);
        $this->assertMatchesRegularExpression('/[A-Z]/', $pw);
        $this->assertMatchesRegularExpression('/[0-9]/', $pw);
        $this->assertDoesNotMatchRegularExpression('/[a-z]/', $pw);
        $this->assertDoesNotMatchRegularExpression('/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/', $pw);
    }

    public function testShuffledNotSequential() {
        $passwords = [];
        for ($i = 0; $i < 5; $i++) {
            $passwords[] = generate_password();
        }
        $unique = array_unique($passwords);
        $this->assertGreaterThan(1, count($unique));
    }
}
