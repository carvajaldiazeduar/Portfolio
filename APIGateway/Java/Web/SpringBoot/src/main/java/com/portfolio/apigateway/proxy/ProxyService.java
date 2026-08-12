package com.portfolio.apigateway.proxy;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

@Service
public class ProxyService {

    private final RestTemplate restTemplate;
    private final String usersUrl;
    private final String ordersUrl;
    private final String productsUrl;

    @Autowired
    public ProxyService(RestTemplate restTemplate,
                        @Value("${app.services.users-url:http://localhost:3001}") String usersUrl,
                        @Value("${app.services.orders-url:http://localhost:3002}") String ordersUrl,
                        @Value("${app.services.products-url:http://localhost:3003}") String productsUrl) {
        this.restTemplate = restTemplate;
        this.usersUrl = usersUrl;
        this.ordersUrl = ordersUrl;
        this.productsUrl = productsUrl;
    }

    public ResponseEntity<String> forward(String prefix, String path) {
        String upstream;
        String remainder;
        if (prefix.equals("/api/users")) {
            upstream = usersUrl;
            remainder = path.substring("/api/users".length());
        } else if (prefix.equals("/api/orders")) {
            upstream = ordersUrl;
            remainder = path.substring("/api/orders".length());
        } else if (prefix.equals("/api/products")) {
            upstream = productsUrl;
            remainder = path.substring("/api/products".length());
        } else {
            upstream = "";
            remainder = path;
        }
        String target = normalize(upstream) + remainder;
        try {
            return restTemplate.getForEntity(target, String.class);
        } catch (RestClientException e) {
            throw new UpstreamException("Upstream service unavailable");
        }
    }

    private static String normalize(String url) {
        if (url.endsWith("/")) return url;
        return url + "/";
    }

    public static class UpstreamException extends RuntimeException {
        public UpstreamException(String message) {
            super(message);
        }
    }
}
