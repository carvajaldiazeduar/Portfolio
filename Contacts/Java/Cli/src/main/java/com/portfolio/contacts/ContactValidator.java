package com.portfolio.contacts;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.regex.Pattern;

public final class ContactValidator {
    private static final Pattern NAME_REGEX = Pattern.compile("^[A-Za-zÀ-ÿ' .-]+$");
    private static final Pattern PHONE_REGEX = Pattern.compile("^[0-9 +().-]{7,20}$");
    private static final Pattern EMAIL_REGEX = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$");

    private ContactValidator() {
    }

    public static Map<String, String> validate(String name, String phone, String email) {
        Map<String, String> errors = new LinkedHashMap<>();
        String n = name == null ? "" : name.trim();
        String p = phone == null ? "" : phone.trim();
        String e = email == null ? "" : email.trim();

        if (n.isEmpty()) {
            errors.put("name", "Name is required");
        } else if (n.length() < 2 || n.length() > 100 || !NAME_REGEX.matcher(n).matches()) {
            errors.put("name", "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)");
        }

        if (p.isEmpty()) {
            errors.put("phone", "Phone is required");
        } else if (!PHONE_REGEX.matcher(p).matches()) {
            errors.put("phone", "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)");
        }

        if (e.isEmpty()) {
            errors.put("email", "Email is required");
        } else if (!EMAIL_REGEX.matcher(e).matches()) {
            errors.put("email", "Invalid email format");
        }

        return errors;
    }
}
