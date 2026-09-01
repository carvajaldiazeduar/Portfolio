package com.portfolio.apigateway.proxy;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("")
public class ProxyController {

    private final ProxyService proxyService;

    public ProxyController(ProxyService proxyService) {
        this.proxyService = proxyService;
    }

    @GetMapping({"/api/users", "/api/users/**"})
    public ResponseEntity<?> users(HttpServletRequest request) {
        return forward(request, "/api/users");
    }

    @GetMapping({"/api/orders", "/api/orders/**"})
    public ResponseEntity<?> orders(HttpServletRequest request) {
        return forward(request, "/api/orders");
    }

    @GetMapping({"/api/products", "/api/products/**"})
    public ResponseEntity<?> products(HttpServletRequest request) {
        return forward(request, "/api/products");
    }

    private ResponseEntity<?> forward(HttpServletRequest request, String prefix) {
        try {
            return proxyService.forward(prefix, request.getRequestURI());
        } catch (ProxyService.UpstreamException e) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body("{\"error\":\"Bad Gateway\",\"message\":\"Upstream service unavailable\"}");
        }
    }
}
