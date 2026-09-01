package com.portfolio.passwordgenerator;

import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.List;

public final class PasswordGenerator {
    public static final String UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    public static final String LOWER = "abcdefghijklmnopqrstuvwxyz";
    public static final String DIGITS = "0123456789";
    public static final String SYMBOLS = "!@#$%^&*()_+-=[]{}|;:,.<>?";

    private static final SecureRandom RANDOM = new SecureRandom();

    private PasswordGenerator() {
    }

    public static String generate(int length, boolean useUpper, boolean useLower, boolean useDigits, boolean useSymbols) {
        if (length < 1) {
            throw new IllegalArgumentException("Password length must be at least 1");
        }

        List<String> categories = new ArrayList<>();
        if (useUpper) {
            categories.add(UPPER);
        }
        if (useLower) {
            categories.add(LOWER);
        }
        if (useDigits) {
            categories.add(DIGITS);
        }
        if (useSymbols) {
            categories.add(SYMBOLS);
        }

        if (categories.isEmpty()) {
            throw new IllegalArgumentException("At least one character category must be enabled");
        }

        if (length < categories.size()) {
            throw new IllegalArgumentException("Password length must be at least " + categories.size()
                    + " when " + categories.size() + " categories are enabled");
        }

        char[] chars = new char[length];
        int index = 0;
        for (String category : categories) {
            chars[index++] = category.charAt(RANDOM.nextInt(category.length()));
        }

        StringBuilder all = new StringBuilder();
        for (String category : categories) {
            all.append(category);
        }
        String allChars = all.toString();
        while (index < length) {
            chars[index++] = allChars.charAt(RANDOM.nextInt(allChars.length()));
        }

        for (int i = chars.length - 1; i > 0; i--) {
            int j = RANDOM.nextInt(i + 1);
            char tmp = chars[i];
            chars[i] = chars[j];
            chars[j] = tmp;
        }

        return new String(chars);
    }
}
