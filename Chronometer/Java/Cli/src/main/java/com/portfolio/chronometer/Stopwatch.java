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

    private final Clock clock;
    private State state = State.STOPPED;
    private long elapsedMillis = 0;
    private long lastStart = 0;
    private final List<Double> laps = new ArrayList<>();

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

    public synchronized State resume() {
        if (state == State.RUNNING) {
            return state;
        }
        lastStart = clock.currentTimeMillis();
        state = State.RUNNING;
        return state;
    }

    public synchronized double pause() {
        if (state == State.RUNNING) {
            elapsedMillis += clock.currentTimeMillis() - lastStart;
        }
        state = State.PAUSED;
        return round3(elapsedMillis / 1000.0);
    }

    public synchronized double reset() {
        state = State.STOPPED;
        elapsedMillis = 0;
        lastStart = 0;
        laps.clear();
        return 0.0;
    }

    public synchronized double lap() {
        double current = round3(elapsed());
        if (state == State.RUNNING) {
            laps.add(current);
        }
        return current;
    }

    public synchronized List<Double> laps() {
        return new ArrayList<>(laps);
    }

    public synchronized double elapsed() {
        if (state == State.RUNNING) {
            return round3((elapsedMillis + clock.currentTimeMillis() - lastStart) / 1000.0);
        }
        return round3(elapsedMillis / 1000.0);
    }

    public synchronized State state() {
        return state;
    }

    private double round3(double value) {
        return Math.round(value * 1000) / 1000.0;
    }
}
