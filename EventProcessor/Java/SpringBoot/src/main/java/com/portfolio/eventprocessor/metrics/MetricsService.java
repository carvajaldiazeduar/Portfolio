package com.portfolio.eventprocessor.metrics;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Component
public class MetricsService {

    private static final class Sample {
        final String name;
        final String[] labels;
        final AtomicLong value = new AtomicLong();

        Sample(String name, String[] labels) {
            this.name = name;
            this.labels = labels;
        }
    }

    private final ConcurrentHashMap<String, Sample> samples = new ConcurrentHashMap<>();
    private final String nl = System.lineSeparator();

    private Sample sample(String name, String... labels) {
        String key = name + "\u0000" + String.join(",", labels);
        return samples.computeIfAbsent(key, k -> new Sample(name, labels));
    }

    public void increment(String name, String... labels) {
        sample(name, labels).value.incrementAndGet();
    }

    public void observe(String name, double seconds, String... labels) {
        sample(name, labels).value.addAndGet((long) (seconds * 1000));
    }

    public String render() {
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, Sample> entry : samples.entrySet()) {
            Sample sample = entry.getValue();
            sb.append(renderSample(sample.name, sample.labels, sample.value.get())).append(nl);
        }
        sb.append("# EOF").append(nl);
        return sb.toString();
    }

    private static String renderSample(String name, String[] labels, long value) {
        StringBuilder sb = new StringBuilder(name);
        if (labels.length > 0) {
            sb.append('{');
            for (int i = 0; i < labels.length; i++) {
                if (i > 0) {
                    sb.append(',');
                }
                sb.append("label").append(i + 1).append("=\"").append(escape(labels[i])).append('"');
            }
            sb.append('}');
        }
        sb.append(' ').append(value);
        return sb.toString();
    }

    private static String escape(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
    }
}