package com.portfolio.apigateway.ratelimit;

import com.portfolio.apigateway.CacheAdapter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.annotation.Order;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@Order(20)
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private final CacheAdapter cache;
    private final int defaultLimit;
    private final int defaultWindow;
    private final Map<String, Integer> routeLimits;
    private final Map<String, Integer> routeWindows;

    public RateLimitFilter(CacheAdapter cache,
                           @Value("${app.rate-limit.default:100}") int defaultLimit,
                           @Value("${app.rate-limit.window:60}") int defaultWindow,
                           @Value("${app.routes.users.limit:50}") int usersLimit,
                           @Value("${app.routes.orders.limit:30}") int ordersLimit,
                           @Value("${app.routes.products.limit:100}") int productsLimit,
                           @Value("${app.routes.users.window:60}") int usersWindow,
                           @Value("${app.routes.orders.window:60}") int ordersWindow,
                           @Value("${app.routes.products.window:60}") int productsWindow) {
        this.cache = cache;
        this.defaultLimit = defaultLimit;
        this.defaultWindow = defaultWindow;
        this.routeLimits = Map.of(
                "/api/users", usersLimit,
                "/api/orders", ordersLimit,
                "/api/products", productsLimit
        );
        this.routeWindows = Map.of(
                "/api/users", usersWindow,
                "/api/orders", ordersWindow,
                "/api/products", productsWindow
        );
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) throws ServletException {
        String path = request.getRequestURI();
        return !path.startsWith("/api/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String path = request.getRequestURI();
        if (!path.startsWith("/api/")) {
            filterChain.doFilter(request, response);
            return;
        }
        String prefix = resolveRoute(path);
        int limit = routeLimits.getOrDefault(prefix, defaultLimit);
        int windowSec = routeWindows.getOrDefault(prefix, defaultWindow);
        String identifier = request.getRemoteAddr();
        String key = "ratelimit:" + path + ":" + identifier;

        long current = cache.increment(key, windowSec);
        int remaining = Math.max(0, limit - (int) current);
        response.setHeader("X-RateLimit-Limit", String.valueOf(limit));
        response.setHeader("X-RateLimit-Remaining", String.valueOf(remaining));
        response.setHeader("X-RateLimit-Reset", String.valueOf((int) (System.currentTimeMillis() / 1000) + windowSec));

        if (current > limit) {
            writeError(response, 429,
                    "Rate limit exceeded. Limit: " + limit + " requests per " + windowSec + "s");
            return;
        }
        filterChain.doFilter(request, response);
    }

    private String resolveRoute(String path) {
        if (path.startsWith("/api/users")) return "/api/users";
        if (path.startsWith("/api/orders")) return "/api/orders";
        if (path.startsWith("/api/products")) return "/api/products";
        return path;
    }

    private void writeError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.getWriter().write("{\"error\":\"" + message + "\"}");
    }
}
