package com.portfolio.eventprocessor.handlers;

import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class DefaultHandler implements JobHandler {

    @Override
    public Map<String, Object> handle(String jobType, Map<String, Object> data, String jobId) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("success", true);
        result.put("processed", data);
        return result;
    }
}
