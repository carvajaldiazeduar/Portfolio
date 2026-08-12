package com.portfolio.chronometer;

import java.util.ArrayList;
import java.util.List;

public class Stopwatch {
    public enum State {
        STOPPED,
        RUNNING,
        PAUSED
    }

    public interface Clock {
        long currentTimeMillis();
    }

    public static class Lap {
        private final double cumulative;
        private final double split;

        Lap(double cumulative, double split) {
            this.cumulative = cumulative;
            this.split = split;
        }

        public double getCumulative() {
            return cumulative;
        }

        public double getSplit() {
            return split;
        }
    }

    private final Clock clock;
    private State state = State.STOPPED;
    private long elapsedMillis = 0;
    private long lastStart = 0;
    private final List<Lap> laps = new ArrayList<>();

    public Stopwatch() {
        this(System::currentTimeMillis);
    }

    public Stopwatch(Clock clock) {
        this.clock = clock;
    }

    public synchronized State start() {
        if (state == State.RUNNING) {
            return state;
        }
        lastStart = clock.currentTimeMillis();
        state = State.RUNNING;
        return state;
    }

    public synchronized void stop() {
        if (state == State.RUNNING) {
            elapsedMillis += clock.currentTimeMillis() - lastStart;
        }
        state = State.STOPPED;
    }

    public synchronized void reset() {
        state = State.STOPPED;
        elapsedMillis = 0;
        lastStart = 0;
        laps.clear();
    }

    public synchronized Lap lap() {
        double current = elapsed();
        if (state == State.RUNNING) {
            double prev = laps.isEmpty() ? 0.0 : laps.get(laps.size() - 1).getCumulative();
            laps.add(new Lap(current, current - prev));
        }
        return laps.isEmpty() ? new Lap(0.0, 0.0) : laps.get(laps.size() - 1);
    }

    public synchronized List<Lap> laps() {
        return new ArrayList<>(laps);
    }

    public synchronized double elapsed() {
        if (state == State.RUNNING) {
            return round3((elapsedMillis + clock.currentTimeMillis() - lastStart) / 1000.0);
        }
        return round3(elapsedMillis / 1000.0);
    }

    public synchronized boolean running() {
        return state == State.RUNNING;
    }

    public synchronized State state() {
        return state;
    }

    private double round3(double value) {
        return Math.round(value * 1000) / 1000.0;
    }
}
