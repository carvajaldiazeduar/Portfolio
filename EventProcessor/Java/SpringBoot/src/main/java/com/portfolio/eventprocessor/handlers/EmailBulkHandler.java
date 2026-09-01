package com.portfolio.eventprocessor.handlers;

import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class EmailBulkHandler implements JobHandler {

    @Override
    public Map<String, Object> handle(String jobType, Map<String, Object> data, String jobId) {
        List<?> recipients = (List<?>) data.getOrDefault("recipients", List.of());
        java.util.List<Map<String, Object>> results = new java.util.ArrayList<>();
        for (Object r : recipients) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("email", r);
            item.put("status", "sent");
            item.put("messageId", "msg_" + System.currentTimeMillis() + "_" + Math.random());
            results.add(item);
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("sent", results.size());
        result.put("results", results);
        return result;
    }
}
