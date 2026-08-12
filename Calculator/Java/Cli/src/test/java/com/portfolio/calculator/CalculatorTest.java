package com.portfolio.calculator;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CalculatorTest {

    @Test
    void addReturnsCorrectSum() {
        assertEquals(5, Calculator.calculate(2, 3, "add"));
        assertEquals(0, Calculator.calculate(-1, 1, "add"));
        assertEquals(0, Calculator.calculate(0, 0, "add"));
    }

    @Test
    void subtractReturnsCorrectDifference() {
        assertEquals(2, Calculator.calculate(5, 3, "subtract"));
        assertEquals(-5, Calculator.calculate(0, 5, "subtract"));
        assertEquals(0, Calculator.calculate(-1, -1, "subtract"));
    }

    @Test
    void multiplyReturnsCorrectProduct() {
        assertEquals(6, Calculator.calculate(2, 3, "multiply"));
        assertEquals(0, Calculator.calculate(0, 5, "multiply"));
        assertEquals(-6, Calculator.calculate(-2, 3, "multiply"));
    }

    @Test
    void divideReturnsCorrectQuotient() {
        assertEquals(2, Calculator.calculate(6, 3, "divide"));
        assertEquals(2.5, Calculator.calculate(5, 2, "divide"));
        assertEquals(0, Calculator.calculate(0, 5, "divide"));
    }

    @Test
    void divideByZeroThrows() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> Calculator.calculate(5, 0, "divide"));
        assertEquals("Cannot divide by zero", ex.getMessage());
    }

    @Test
    void invalidOperatorThrows() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> Calculator.calculate(2, 3, "power"));
        assertEquals("Invalid operator", ex.getMessage());
    }
}
