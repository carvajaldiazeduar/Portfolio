package com.portfolio.chronometer;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class StopwatchTest {

    private static class FakeClock implements Stopwatch.Clock {
        long time;

        FakeClock(long time) {
            this.time = time;
        }

        @Override
        public long currentTimeMillis() {
            return time;
        }
    }

    @Test
    void initialStateIsStopped() {
        Stopwatch sw = new Stopwatch(new FakeClock(0));
        assertEquals(Stopwatch.State.STOPPED, sw.state());
        assertEquals(0, sw.elapsed(), 1e-9);
    }

    @Test
    void startSetsRunning() {
        Stopwatch sw = new Stopwatch(new FakeClock(0));
        sw.start();
        assertEquals(Stopwatch.State.RUNNING, sw.state());
    }

    @Test
    void pauseAccumulatesElapsed() {
        FakeClock clock = new FakeClock(1000);
        Stopwatch sw = new Stopwatch(clock);
        sw.start();
        clock.time = 3500;
        sw.pause();
        assertEquals(Stopwatch.State.PAUSED, sw.state());
        assertEquals(2.5, sw.elapsed(), 1e-9);
    }

    @Test
    void resumeContinuesFromPaused() {
        FakeClock clock = new FakeClock(1000);
        Stopwatch sw = new Stopwatch(clock);
        sw.start();
        clock.time = 2000;
        sw.pause();
        assertEquals(1.0, sw.elapsed(), 1e-9);
        sw.resume();
        clock.time = 4000;
        sw.pause();
        assertEquals(3.0, sw.elapsed(), 1e-9);
    }

    @Test
    void elapsedWhileRunning() {
        FakeClock clock = new FakeClock(1000);
        Stopwatch sw = new Stopwatch(clock);
        sw.start();
        clock.time = 2500;
        assertEquals(1.5, sw.elapsed(), 1e-9);
    }

    @Test
    void resetZerosEverything() {
        FakeClock clock = new FakeClock(1000);
        Stopwatch sw = new Stopwatch(clock);
        sw.start();
        clock.time = 3000;
        sw.pause();
        sw.lap();
        sw.reset();
        assertEquals(Stopwatch.State.STOPPED, sw.state());
        assertEquals(0, sw.elapsed(), 1e-9);
        assertEquals(0, sw.laps().size());
    }

    @Test
    void lapRecordsCurrentTime() {
        FakeClock clock = new FakeClock(1000);
        Stopwatch sw = new Stopwatch(clock);
        sw.start();
        clock.time = 2500;
        sw.lap();
        clock.time = 4000;
        sw.lap();
        assertEquals(2, sw.laps().size());
        assertEquals(1.5, sw.laps().get(0), 1e-9);
        assertEquals(3.0, sw.laps().get(1), 1e-9);
    }

    @Test
    void lapIgnoredWhenStopped() {
        Stopwatch sw = new Stopwatch(new FakeClock(0));
        sw.lap();
        assertEquals(0, sw.laps().size());
    }
}
