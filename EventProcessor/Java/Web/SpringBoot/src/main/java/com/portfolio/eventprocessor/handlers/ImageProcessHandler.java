package com.portfolio.eventprocessor.handlers;

import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class ImageProcessHandler implements JobHandler {

    @Override
    public Map<String, Object> handle(String jobType, Map<String, Object> data, String jobId) {
        String imageUrl = (String) data.getOrDefault("imageUrl", "");
        java.util.List<String> operations = (java.util.List<String>) data.getOrDefault("operations", java.util.List.of("resize", "optimize"));
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("originalUrl", imageUrl);
        result.put("processedUrl", imageUrl.replaceAll("\\.(jpg|jpeg|png|webp)$", "_processed.$1"));
        result.put("operations", operations);
        result.put("completedAt", Instant.now().toString());
        return result;
    }
}
