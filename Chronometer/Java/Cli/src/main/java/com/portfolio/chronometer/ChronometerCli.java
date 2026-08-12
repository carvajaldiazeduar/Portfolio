package com.portfolio.chronometer;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.List;

public class ChronometerCli {
    private final Stopwatch stopwatch = new Stopwatch();
    private final BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));

    public static void main(String[] args) {
        new ChronometerCli().run();
    }

    public void run() {
        render();
        while (true) {
            String key = readKey();
            switch (key) {
                case "s" -> {
                    stopwatch.start();
                    render();
                }
                case "p" -> {
                    if (stopwatch.state() == Stopwatch.State.RUNNING) {
                        stopwatch.pause();
                        render();
                    }
                }
                case "r" -> {
                    stopwatch.reset();
                    render();
                }
                case "l" -> {
                    if (stopwatch.state() == Stopwatch.State.RUNNING) {
                        stopwatch.lap();
                        render();
                    }
                }
                case "q" -> {
                    System.out.println("Goodbye!");
                    return;
                }
                default -> {
                }
            }
        }
    }

    private void render() {
        String state = switch (stopwatch.state()) {
            case RUNNING -> "Running";
            case PAUSED -> "Paused";
            case STOPPED -> "Stopped";
        };
        System.out.println();
        System.out.println("=== Chronometer ===");
        System.out.println("  Status: " + state);
        System.out.println("  Time:   " + formatTime(stopwatch.elapsed()));
        List<Double> laps = stopwatch.laps();
        for (int i = 0; i < laps.size(); i++) {
            double cumulative = laps.get(i);
            double split = i == 0 ? cumulative : cumulative - laps.get(i - 1);
            System.out.println("  Lap " + (i + 1) + ": " + formatTime(cumulative) + "  (+" + formatTime(split) + ")");
        }
        System.out.println("Controls:");
        System.out.println("  [S]  Start");
        System.out.println("  [P]  Pause");
        System.out.println("  [R]  Reset");
        System.out.println("  [L]  Lap");
        System.out.println("  [Q]  Quit");
    }

    private static String formatTime(double seconds) {
        long totalMs = Math.round(seconds * 1000);
        long hours = totalMs / 3600000;
        long minutes = (totalMs % 3600000) / 60000;
        long secs = (totalMs % 60000) / 1000;
        long millis = totalMs % 1000;
        return String.format("%02d:%02d:%02d.%03d", hours, minutes, secs, millis);
    }

    private String readKey() {
        try {
            String line = reader.readLine();
            return line == null ? "q" : line.trim().toLowerCase();
        } catch (IOException e) {
            return "q";
        }
    }
}
