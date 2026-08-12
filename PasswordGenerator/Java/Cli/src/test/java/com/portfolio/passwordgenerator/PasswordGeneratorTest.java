package com.portfolio.passwordgenerator;

import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PasswordGeneratorTest {

    @Test
    void defaultLength() {
        String pw = PasswordGenerator.generate(16, true, true, true, true);
        assertEquals(16, pw.length());
    }

    @Test
    void customLength() {
        String pw = PasswordGenerator.generate(24, true, true, true, true);
        assertEquals(24, pw.length());
    }

    @Test
    void minLength() {
        String pw = PasswordGenerator.generate(1, true, false, false, false);
        assertEquals(1, pw.length());
    }

    @Test
    void uppercasePresent() {
        String pw = PasswordGenerator.generate(10, true, false, false, false);
        assertTrue(pw.matches(".*[A-Z].*"));
    }

    @Test
    void lowercasePresent() {
        String pw = PasswordGenerator.generate(10, false, true, false, false);
        assertTrue(pw.matches(".*[a-z].*"));
    }

    @Test
    void digitsPresent() {
        String pw = PasswordGenerator.generate(10, false, false, true, false);
        assertTrue(pw.matches(".*[0-9].*"));
    }

    @Test
    void symbolsPresent() {
        String pw = PasswordGenerator.generate(10, false, false, false, true);
        assertTrue(pw.matches(".*[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?].*"));
    }

    @Test
    void noUppercase() {
        String pw = PasswordGenerator.generate(16, false, true, true, true);
        assertFalse(pw.matches(".*[A-Z].*"));
    }

    @Test
    void noSymbols() {
        String pw = PasswordGenerator.generate(16, true, true, true, false);
        assertFalse(pw.matches(".*[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?].*"));
    }

    @Test
    void noLowercase() {
        String pw = PasswordGenerator.generate(16, true, false, true, true);
        assertFalse(pw.matches(".*[a-z].*"));
    }

    @Test
    void noDigits() {
        String pw = PasswordGenerator.generate(16, true, true, false, true);
        assertFalse(pw.matches(".*[0-9].*"));
    }

    @Test
    void allDisabledThrows() {
        assertThrows(IllegalArgumentException.class, () ->
                PasswordGenerator.generate(10, false, false, false, false));
    }

    @Test
    void lengthZeroThrows() {
        assertThrows(IllegalArgumentException.class, () ->
                PasswordGenerator.generate(0, true, true, true, true));
    }

    @Test
    void negativeLengthThrows() {
        assertThrows(IllegalArgumentException.class, () ->
                PasswordGenerator.generate(-5, true, true, true, true));
    }

    @Test
    void lengthTooShortForCategories() {
        assertThrows(IllegalArgumentException.class, () ->
                PasswordGenerator.generate(2, true, true, true, true));
    }

    @Test
    void atLeastOneFromEachEnabled() {
        String pw = PasswordGenerator.generate(20, true, true, true, true);
        assertTrue(pw.matches(".*[A-Z].*"));
        assertTrue(pw.matches(".*[a-z].*"));
        assertTrue(pw.matches(".*[0-9].*"));
        assertTrue(pw.matches(".*[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?].*"));
    }

    @Test
    void onlyUppercaseAndDigits() {
        String pw = PasswordGenerator.generate(12, true, false, true, false);
        assertTrue(pw.matches(".*[A-Z].*"));
        assertTrue(pw.matches(".*[0-9].*"));
        assertFalse(pw.matches(".*[a-z].*"));
        assertFalse(pw.matches(".*[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?].*"));
    }

    @Test
    void shuffledNotSequential() {
        Set<String> passwords = new HashSet<>();
        for (int i = 0; i < 5; i++) {
            passwords.add(PasswordGenerator.generate(16, true, true, true, true));
        }
        assertTrue(passwords.size() > 1);
    }
}
