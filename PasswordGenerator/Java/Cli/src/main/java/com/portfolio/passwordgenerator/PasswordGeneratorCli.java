package com.portfolio.passwordgenerator;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class PasswordGeneratorCli {
    private final BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));

    public static void main(String[] args) {
        new PasswordGeneratorCli().run(args);
    }

    public void run(String[] args) {
        if (args.length > 0) {
            int length = 16;
            boolean useUpper = true;
            boolean useLower = true;
            boolean useDigits = true;
            boolean useSymbols = true;

            for (int i = 0; i < args.length; i++) {
                switch (args[i]) {
                    case "-l":
                    case "--length":
                        if (i + 1 < args.length) {
                            try {
                                length = Integer.parseInt(args[++i]);
                            } catch (NumberFormatException e) {
                                length = 0;
                            }
                        }
                        break;
                    case "--no-upper":
                        useUpper = false;
                        break;
                    case "--no-lower":
                        useLower = false;
                        break;
                    case "--no-digits":
                        useDigits = false;
                        break;
                    case "--no-symbols":
                        useSymbols = false;
                        break;
                    default:
                        break;
                }
            }

            try {
                System.out.println(PasswordGenerator.generate(length, useUpper, useLower, useDigits, useSymbols));
            } catch (IllegalArgumentException e) {
                System.err.println("Error: " + e.getMessage());
                System.exit(1);
            }
        } else {
            showMenu();
        }
    }

    private void showMenu() {
        System.out.println("=== Password Generator ===");

        System.out.print("Length (default 16): ");
        int length = 16;
        try {
            length = Integer.parseInt(readLine().trim());
        } catch (NumberFormatException e) {
            length = 16;
        }
        if (length < 1) {
            length = 16;
        }

        System.out.print("Include uppercase? (Y/n): ");
        boolean useUpper = !"n".equalsIgnoreCase(readLine().trim());
        System.out.print("Include lowercase? (Y/n): ");
        boolean useLower = !"n".equalsIgnoreCase(readLine().trim());
        System.out.print("Include digits? (Y/n): ");
        boolean useDigits = !"n".equalsIgnoreCase(readLine().trim());
        System.out.print("Include symbols? (Y/n): ");
        boolean useSymbols = !"n".equalsIgnoreCase(readLine().trim());

        try {
            String password = PasswordGenerator.generate(length, useUpper, useLower, useDigits, useSymbols);
            System.out.println("\nGenerated password: " + password);
        } catch (IllegalArgumentException e) {
            System.out.println("Error: " + e.getMessage());
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
