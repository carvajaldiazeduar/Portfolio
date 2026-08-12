package com.portfolio.apigateway.auth;

import com.portfolio.apigateway.JwtResponse;
import com.portfolio.apigateway.auth.JwtUtil;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("")
public class AuthController {

    private final String jwtSecret;

    public AuthController(@Value("${app.jwt-secret:dev-secret-change-in-production}") String jwtSecret) {
        this.jwtSecret = jwtSecret;
    }

    @PostMapping("/auth/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String password = body.get("password");
        if (username == null || password == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Username and password required"));
        }
        if ("admin".equals(username) && "admin".equals(password)) {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("id", 1);
            payload.put("username", "admin");
            payload.put("roles", java.util.List.of("admin"));
            payload.put("exp", (System.currentTimeMillis() / 1000) + 3600);
            String token = JwtUtil.sign(payload, jwtSecret);
            return ResponseEntity.ok(new JwtResponse(token, "1h"));
        }
        if ("user".equals(username) && "user".equals(password)) {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("id", 2);
            payload.put("username", "user");
            payload.put("roles", java.util.List.of("user"));
            payload.put("exp", (System.currentTimeMillis() / 1000) + 3600);
            String token = JwtUtil.sign(payload, jwtSecret);
            return ResponseEntity.ok(new JwtResponse(token, "1h"));
        }
        return ResponseEntity.status(401)
                .body(Map.of("error", "Invalid credentials"));
    }
}
