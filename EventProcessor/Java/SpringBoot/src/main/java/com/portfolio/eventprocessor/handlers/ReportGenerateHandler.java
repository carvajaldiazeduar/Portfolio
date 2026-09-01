package com.portfolio.eventprocessor.handlers;

import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class ReportGenerateHandler implements JobHandler {

    @Override
    public Map<String, Object> handle(String jobType, Map<String, Object> data, String jobId) {
        String reportType = (String) data.getOrDefault("reportType", "report");
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("reportType", reportType);
        result.put("fileName", reportType + "_" + System.currentTimeMillis() + ".pdf");
        result.put("fileSize", (long) (Math.random() * 500000) + 100000);
        result.put("generatedAt", Instant.now().toString());
        result.put("downloadUrl", "/reports/" + reportType + "_" + System.currentTimeMillis() + ".pdf");
        return result;
    }
}
