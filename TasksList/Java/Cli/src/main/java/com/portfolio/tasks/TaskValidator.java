package com.portfolio.tasks;

import java.util.LinkedHashMap;
import java.util.Map;

public final class TaskValidator {
    private TaskValidator() {
    }

    public static Map<String, String> validate(String title) {
        Map<String, String> errors = new LinkedHashMap<>();
        String t = title == null ? "" : title.trim();
        if (t.isEmpty()) {
            errors.put("title", "Title is required");
        }
        return errors;
    }
}
