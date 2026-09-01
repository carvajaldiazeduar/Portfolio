package com.portfolio.eventprocessor;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import com.portfolio.eventprocessor.handlers.JobHandler;
import com.portfolio.eventprocessor.handlers.JobRegistry;
import com.portfolio.eventprocessor.metrics.MetricsService;
import com.portfolio.eventprocessor.queue.QueueAdapter;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;

@Component
@Profile("worker")
public class JobWorker implements ApplicationRunner {

    private final QueueAdapter queue;
    private final JobRegistry registry;
    private final MetricsService metrics;

    public JobWorker(QueueAdapter queue, JobRegistry registry, MetricsService metrics) {
        this.queue = queue;
        this.registry = registry;
        this.metrics = metrics;
    }

    @Override
    public void run(ApplicationArguments args) {
        queue.connect();
        String[] queues = {"image.process", "email.bulk", "report.generate", "default"};
        for (String name : queues) {
            queue.subscribe(name, (data, id) -> {
                long start = System.nanoTime();
                try {
                    JobHandler handler = registry.isRegistered(name) ? registry.get(name) : registry.get("default");
                    handler.handle(name, data, id);
                    metrics.increment("jobs_processed_total", name, "success");
                } catch (Exception e) {
                    metrics.increment("jobs_processed_total", name, "failed");
                } finally {
                    double seconds = (System.nanoTime() - start) / 1_000_000_000.0;
                    metrics.observe("jobs_processing_duration_seconds", seconds, name);
                }
            });
        }
    }
}
