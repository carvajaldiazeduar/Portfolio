package com.portfolio.conversor;

import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ConversorController {
    @GetMapping("/categories")
    public Map<String, String[]> categories() {
        Map<String, String[]> result = new LinkedHashMap<>();
        for (String cat : Conversor.listCategories()) {
            result.put(cat, Conversor.CATEGORY_UNITS.get(cat));
        }
        return result;
    }

    @PostMapping("/convert")
    public ResponseEntity<?> convert(@RequestBody ConvertRequest request) {
        if (request.getValue() == null || request.getFrom() == null || request.getTo() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Missing fields: value, from, to"));
        }
        try {
            double result = Conversor.convert(request.getValue(), request.getFrom(), request.getTo());
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("result", result);
            body.put("from", request.getFrom());
            body.put("to", request.getTo());
            body.put("value", request.getValue());
            return ResponseEntity.ok(body);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, String>> onUnreadable() {
        return ResponseEntity.badRequest().body(Map.of("error", "Invalid JSON"));
    }
}
