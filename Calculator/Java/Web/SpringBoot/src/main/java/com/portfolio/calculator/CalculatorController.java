package com.portfolio.calculator;

import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/calculate")
public class CalculatorController {
    private static final Set<String> OPERATORS = Set.of("add", "subtract", "multiply", "divide");

    @PostMapping
    public ResponseEntity<?> calculate(@RequestBody CalculateRequest request) {
        if (request.getA() == null || request.getB() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid number input"));
        }
        String operator = request.getOperator();
        if (operator == null || !OPERATORS.contains(operator)) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid operator"));
        }
        if ("divide".equals(operator) && request.getB() == 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Cannot divide by zero"));
        }
        double result = Calculator.calculate(request.getA(), request.getB(), operator);
        return ResponseEntity.ok(Map.of("result", result));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, String>> onUnreadable() {
        return ResponseEntity.badRequest().body(Map.of("error", "Invalid number input"));
    }
}
