import time
from flask import Flask, render_template, jsonify

app = Flask(__name__)

state = {
    "running": False,
    "start_time": 0.0,
    "elapsed": 0.0,
    "laps": [],
}


def get_current_time():
    if state["running"]:
        return state["elapsed"] + (time.time() - state["start_time"])
    return state["elapsed"]


def format_time(seconds):
    total_ms = round(seconds * 1000)
    hours = total_ms // 3600000
    minutes = (total_ms % 3600000) // 60000
    secs = (total_ms % 60000) // 1000
    millis = total_ms % 1000
    return f"{hours:02d}:{minutes:02d}:{secs:02d}.{millis:03d}"


def make_response():
    current = get_current_time()
    laps = [
        {"cumulative": c, "split": s, "cumulative_str": format_time(c), "split_str": format_time(s)}
        for c, s in state["laps"]
    ]
    return {
        "running": state["running"],
        "time": round(current, 3),
        "time_str": format_time(current),
        "laps": laps,
    }


@app.route("/")
def index():
    return render_template("chronometer.html")


@app.route("/api/state")
def get_state():
    return jsonify(make_response())


@app.route("/api/start")
def start():
    if not state["running"]:
        state["start_time"] = time.time()
        state["running"] = True
    return jsonify(make_response())


@app.route("/api/stop")
def stop():
    if state["running"]:
        state["elapsed"] += time.time() - state["start_time"]
        state["running"] = False
    return jsonify(make_response())


@app.route("/api/reset")
def reset():
    state["running"] = False
    state["start_time"] = 0.0
    state["elapsed"] = 0.0
    state["laps"] = []
    return jsonify(make_response())


@app.route("/api/lap")
def lap():
    if state["running"]:
        current = state["elapsed"] + (time.time() - state["start_time"])
        prev = state["laps"][-1][0] if state["laps"] else 0.0
        state["laps"].append((current, current - prev))
    return jsonify(make_response())


if __name__ == "__main__":
    app.run(debug=True)
