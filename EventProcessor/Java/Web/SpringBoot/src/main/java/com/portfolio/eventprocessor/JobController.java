package com.portfolio.eventprocessor;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.portfolio.eventprocessor.handlers.JobRegistry;
import com.portfolio.eventprocessor.metrics.MetricsService;
import com.portfolio.eventprocessor.queue.QueueAdapter;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("")
public class JobController {

    private final QueueAdapter queue;
    private final JobRegistry registry;
    private final MetricsService metrics;

    public JobController(QueueAdapter queue, JobRegistry registry, MetricsService metrics) {
        this.queue = queue;
        this.registry = registry;
        this.metrics = metrics;
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", "ok");
        body.put("timestamp", Instant.now().toString());
        return body;
    }

    @GetMapping("/api/queues")
    public Map<String, Object> queues() {
        List<String> names = new java.util.ArrayList<>(registry.handlers().keySet());
        return Map.of("queues", names);
    }

    @PostMapping("/api/jobs")
    public ResponseEntity<?> publishJob(@RequestBody Map<String, Object> body) {
        String type = (String) body.get("type");
        Object data = body.get("data");
        if (type == null || type.isBlank() || data == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Type and data are required"));
        }
        if (!registry.isRegistered(type)) {
            return ResponseEntity.badRequest().body(Map.of("error", "Unknown job type: " + type));
        }
        try {
            queue.publish(type, body);
            metrics.increment("jobs_published_total", type);
            Map<String, Object> response = new LinkedHashMap<>();
            response.put("message", "Job queued");
            response.put("type", type);
            response.put("status", "pending");
            return ResponseEntity.accepted().body(response);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "Failed to queue job"));
        }
    }

    @PostMapping("/api/jobs/batch")
    public ResponseEntity<?> publishBatch(@RequestBody Map<String, Object> body) {
        Object jobsObj = body.get("jobs");
        if (!(jobsObj instanceof List<?>) || ((List<?>) jobsObj).isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Jobs array is required"));
        }
        List<?> jobs = (List<?>) jobsObj;
        try {
            for (Object job : jobs) {
                Map<String, Object> jobBody = (Map<String, Object>) job;
                String type = (String) jobBody.get("type");
                queue.publish(type, jobBody);
                metrics.increment("jobs_published_total", type);
            }
            Map<String, Object> response = new LinkedHashMap<>();
            response.put("message", jobs.size() + " jobs queued");
            response.put("status", "pending");
            return ResponseEntity.accepted().body(response);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "Failed to queue jobs"));
        }
    }
}
