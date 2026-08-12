package com.portfolio.calculator;

public final class Calculator {
    private Calculator() {
    }

    public static double calculate(double a, double b, String operator) {
        return switch (operator) {
            case "add" -> a + b;
            case "subtract" -> a - b;
            case "multiply" -> a * b;
            case "divide" -> divide(a, b);
            default -> throw new IllegalArgumentException("Invalid operator");
        };
    }

    private static double divide(double a, double b) {
        if (b == 0) {
            throw new IllegalArgumentException("Cannot divide by zero");
        }
        return a / b;
    }
}
