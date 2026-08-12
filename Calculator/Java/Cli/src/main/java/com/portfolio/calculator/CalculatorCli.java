package com.portfolio.calculator;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class CalculatorCli {
    private final BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));

    public static void main(String[] args) {
        new CalculatorCli().run();
    }

    public void run() {
        while (true) {
            System.out.println("\n=== Simple Calculator ===");
            System.out.println("1. Add");
            System.out.println("2. Subtract");
            System.out.println("3. Multiply");
            System.out.println("4. Divide");
            System.out.println("5. Exit");
            System.out.print("Choose an option (1-5): ");
            String choice = readLine().trim();

            if ("5".equals(choice)) {
                System.out.println("Goodbye!");
                return;
            }

            String operator = switch (choice) {
                case "1" -> "add";
                case "2" -> "subtract";
                case "3" -> "multiply";
                case "4" -> "divide";
                default -> null;
            };

            if (operator == null) {
                System.out.println("Invalid option. Please try again.");
                continue;
            }

            double num1 = readNumber("Enter first number: ");
            double num2 = readNumber("Enter second number: ");

            try {
                double result = Calculator.calculate(num1, num2, operator);
                System.out.println("\n" + num1 + " " + operator + " " + num2 + " = " + result);
            } catch (IllegalArgumentException e) {
                System.out.println("\n" + num1 + " " + operator + " " + num2 + " = " + e.getMessage());
            }
        }
    }

    private double readNumber(String prompt) {
        while (true) {
            System.out.print(prompt);
            try {
                return Double.parseDouble(readLine().trim());
            } catch (NumberFormatException e) {
                System.out.println("Invalid input. Please enter a number.");
            }
        }
    }

    private String readLine() {
        try {
            return reader.readLine();
        } catch (IOException e) {
            return "";
        }
    }
}
