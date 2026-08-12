package com.portfolio.inboxes;

import java.util.LinkedHashMap;
import java.util.Map;

public final class MessageValidator {
    private MessageValidator() {
    }

    public static Map<String, String> validate(String from, String subject, String body) {
        Map<String, String> errors = new LinkedHashMap<>();
        String f = from == null ? "" : from.trim();
        String s = subject == null ? "" : subject.trim();
        String b = body == null ? "" : body.trim();

        if (f.isEmpty()) {
            errors.put("from", "From is required");
        } else if (f.length() > 255) {
            errors.put("from", "From must be 1-255 characters");
        }

        if (s.isEmpty()) {
            errors.put("subject", "Subject is required");
        } else if (s.length() > 300) {
            errors.put("subject", "Subject must be 1-300 characters");
        }

        if (b.isEmpty()) {
            errors.put("body", "Body is required");
        } else if (b.length() > 1000) {
            errors.put("body", "Body must be 1-1000 characters");
        }

        return errors;
    }
}
