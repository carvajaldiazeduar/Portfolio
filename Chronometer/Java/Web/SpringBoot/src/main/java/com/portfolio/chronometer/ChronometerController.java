package com.portfolio.chronometer;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ChronometerController {
    private final Stopwatch stopwatch = new Stopwatch();

    @GetMapping("/state")
    public Map<String, Object> state() {
        return response();
    }

    @PostMapping("/start")
    public Map<String, Object> start() {
        stopwatch.start();
        return response();
    }

    @PostMapping("/stop")
    public Map<String, Object> stop() {
        stopwatch.stop();
        return response();
    }

    @PostMapping("/reset")
    public Map<String, Object> reset() {
        stopwatch.reset();
        return response();
    }

    @PostMapping("/lap")
    public Map<String, Object> lap() {
        stopwatch.lap();
        return response();
    }

    private Map<String, Object> response() {
        double current = stopwatch.elapsed();
        List<Map<String, Object>> laps = new ArrayList<>();
        for (Stopwatch.Lap lap : stopwatch.laps()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("cumulative", lap.getCumulative());
            item.put("split", lap.getSplit());
            item.put("cumulative_str", formatTime(lap.getCumulative()));
            item.put("split_str", formatTime(lap.getSplit()));
            laps.add(item);
        }
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("running", stopwatch.running());
        body.put("time", current);
        body.put("time_str", formatTime(current));
        body.put("laps", laps);
        return body;
    }

    private String formatTime(double seconds) {
        long totalMs = Math.round(seconds * 1000);
        long hours = totalMs / 3600000;
        long minutes = (totalMs % 3600000) / 60000;
        long secs = (totalMs % 60000) / 1000;
        long millis = totalMs % 1000;
        return String.format("%02d:%02d:%02d.%03d", hours, minutes, secs, millis);
    }
}
