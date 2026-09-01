package com.portfolio.eventprocessor.handlers;

import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class JobRegistry {

    private final ImageProcessHandler imageProcess;
    private final EmailBulkHandler emailBulk;
    private final ReportGenerateHandler reportGenerate;
    private final DefaultHandler defaultHandler;
    private final Map<String, JobHandler> handlers = new LinkedHashMap<>();

    public JobRegistry(ImageProcessHandler imageProcess, EmailBulkHandler emailBulk,
                       ReportGenerateHandler reportGenerate, DefaultHandler defaultHandler) {
        this.imageProcess = imageProcess;
        this.emailBulk = emailBulk;
        this.reportGenerate = reportGenerate;
        this.defaultHandler = defaultHandler;
    }

    @PostConstruct
    public void init() {
        handlers.put("image.process", imageProcess);
        handlers.put("email.bulk", emailBulk);
        handlers.put("report.generate", reportGenerate);
    }

    public Map<String, JobHandler> handlers() {
        return handlers;
    }

    public JobHandler get(String type) {
        return handlers.getOrDefault(type, defaultHandler);
    }

    public boolean isRegistered(String type) {
        return handlers.containsKey(type);
    }
}
