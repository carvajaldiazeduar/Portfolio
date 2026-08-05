import time
import sys
from terminal import TerminalAdapter


def format_time(seconds):
    total_ms = round(seconds * 1000)
    hours = total_ms // 3600000
    minutes = (total_ms % 3600000) // 60000
    secs = (total_ms % 60000) // 1000
    millis = total_ms % 1000
    return f"{hours:02d}:{minutes:02d}:{secs:02d}.{millis:03d}"


def draw(status, elapsed, laps):
    print("\033[2J\033[H", end="")
    print("=== Chronometer ===")
    print()
    print(f"  Status: {status}")
    print(f"  Time:   {format_time(elapsed)}")
    if laps:
        print()
        for i, (cumulative, split) in enumerate(laps, 1):
            print(f"  Lap {i}: {format_time(cumulative)}  (+{format_time(split)})")
    print()
    print("Controls:")
    print("  [S]  Start")
    print("  [P]  Stop")
    print("  [R]  Reset")
    print("  [L]  Lap")
    print("  [Q]  Quit")


def run(terminal):
    running = False
    start_time = 0.0
    elapsed = 0.0
    laps = []
    first_draw = True

    terminal.setup()

    try:
        while True:
            if running:
                current_elapsed = elapsed + (time.time() - start_time)
            else:
                current_elapsed = elapsed

            if first_draw:
                draw("Stopped", 0.0, [])
                first_draw = False
            elif running:
                draw("Running", current_elapsed, laps)

            key = terminal.get_key()

            if key == "s" and not running:
                start_time = time.time()
                running = True
            elif key == "p" and running:
                elapsed += time.time() - start_time
                running = False
                draw("Stopped", elapsed, laps)
            elif key == "r":
                running = False
                elapsed = 0.0
                start_time = 0.0
                laps = []
                draw("Stopped", 0.0, [])
            elif key == "l" and running:
                lap_time = elapsed + (time.time() - start_time)
                prev = laps[-1][0] if laps else 0.0
                laps.append((lap_time, lap_time - prev))
                draw("Running", lap_time, laps)
            elif key == "q":
                print("\033[2J\033[HGoodbye!")
                break

            time.sleep(0.05)
    finally:
        terminal.restore()


if __name__ == "__main__":
    if sys.platform == "win32":
        from windows.terminal import WindowsTerminal as TermImpl
    else:
        from unix.terminal import UnixTerminal as TermImpl
    run(TermImpl())
