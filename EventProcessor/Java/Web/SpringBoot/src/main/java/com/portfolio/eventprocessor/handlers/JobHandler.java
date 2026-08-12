package com.portfolio.eventprocessor.handlers;

import java.util.Map;

public interface JobHandler {
    Map<String, Object> handle(String jobType, Map<String, Object> data, String jobId);
}
