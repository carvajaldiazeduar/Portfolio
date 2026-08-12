package com.portfolio.eventprocessor.metrics;

import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Order(5)
@Component
public class MetricsFilter extends OncePerRequestFilter {

    private final MetricsService metrics;

    public MetricsFilter(MetricsService metrics) {
        this.metrics = metrics;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        long start = System.nanoTime();
        try {
            filterChain.doFilter(request, response);
        } finally {
            double seconds = (System.nanoTime() - start) / 1_000_000_000.0;
            metrics.increment("http_requests_total", request.getMethod(), request.getRequestURI(), String.valueOf(response.getStatus()));
            metrics.observe("http_request_duration_seconds", seconds, request.getMethod(), request.getRequestURI(), String.valueOf(response.getStatus()));
        }
    }
}
