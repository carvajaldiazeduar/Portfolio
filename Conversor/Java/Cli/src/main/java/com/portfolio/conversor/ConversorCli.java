package com.portfolio.conversor;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class ConversorCli {
    private final BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));

    public static void main(String[] args) {
        new ConversorCli().run();
    }

    public void run() {
        System.out.println("=== Unit Converter ===");
        while (true) {
            System.out.println("\nCategories:");
            String[] cats = Conversor.categories();
            for (int i = 0; i < cats.length; i++) {
                System.out.println("  " + (i + 1) + ". " + cats[i]);
            }
            System.out.println("  0. Exit");
            System.out.print("Select category: ");
            String input = readLine().trim();

            if ("0".equals(input)) {
                System.out.println("Goodbye!");
                return;
            }

            int choice;
            try {
                choice = Integer.parseInt(input);
            } catch (NumberFormatException e) {
                System.out.println("Invalid choice");
                continue;
            }
            if (choice < 1 || choice > cats.length) {
                System.out.println("Invalid choice");
                continue;
            }

            String category = cats[choice - 1];
            String[] units = Conversor.unitsFor(category);

            System.out.println("\nUnits (" + category + "):");
            for (int i = 0; i < units.length; i++) {
                System.out.println("  " + (i + 1) + ". " + units[i]);
            }

            System.out.print("Select from unit: ");
            int fromIdx = readIndex(units);
            if (fromIdx < 0) {
                System.out.println("Invalid");
                continue;
            }

            System.out.print("Select to unit: ");
            int toIdx = readIndex(units);
            if (toIdx < 0) {
                System.out.println("Invalid");
                continue;
            }

            System.out.print("Enter value: ");
            double value;
            try {
                value = Double.parseDouble(readLine().trim());
            } catch (NumberFormatException e) {
                System.out.println("Invalid number");
                continue;
            }

            try {
                double result = Conversor.convert(value, units[fromIdx], units[toIdx]);
                System.out.println("\nResult: " + value + " " + units[fromIdx] + " = " + result + " " + units[toIdx]);
            } catch (IllegalArgumentException e) {
                System.out.println("Error: " + e.getMessage());
            }
        }
    }

    private int readIndex(String[] units) {
        try {
            int idx = Integer.parseInt(readLine().trim()) - 1;
            if (idx < 0 || idx >= units.length) {
                return -1;
            }
            return idx;
        } catch (NumberFormatException e) {
            return -1;
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
