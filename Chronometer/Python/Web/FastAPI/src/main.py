from fastapi import FastAPI
from fastapi.responses import HTMLResponse, RedirectResponse
import os
import time

app = FastAPI()


@app.get("/swagger", include_in_schema=False)
async def swagger():
    return RedirectResponse("/docs")

timer = {
    'running': False,
    'start_time': None,
    'elapsed': 0.0,
    'laps': [],
}


def _get_elapsed():
    if timer['running'] and timer['start_time']:
        return timer['elapsed'] + (time.time() - timer['start_time'])
    return timer['elapsed']


@app.get("/", response_class=HTMLResponse)
async def index():
    html_path = os.path.join(os.path.dirname(__file__), "static", "index.html")
    with open(html_path, encoding="utf-8") as f:
        return f.read()


@app.get("/api/state")
async def get_state():
    return {
        'running': timer['running'],
        'elapsed': _get_elapsed(),
        'laps': timer['laps'],
    }


@app.post("/api/start")
async def start():
    if not timer['running']:
        timer['running'] = True
        timer['start_time'] = time.time()
    return {'running': True, 'elapsed': _get_elapsed()}


@app.post("/api/stop")
async def stop():
    if timer['running']:
        timer['elapsed'] += (time.time() - timer['start_time'])
        timer['running'] = False
        timer['start_time'] = None
    return {'running': False, 'elapsed': timer['elapsed']}


@app.post("/api/reset")
async def reset():
    timer['running'] = False
    timer['start_time'] = None
    timer['elapsed'] = 0.0
    timer['laps'] = []
    return {'running': False, 'elapsed': 0.0, 'laps': []}


@app.post("/api/lap")
async def add_lap():
    if timer['running']:
        lap_time = _get_elapsed()
        timer['laps'].append(lap_time)
        return {'lap': lap_time, 'laps': timer['laps']}
    return {'error': 'Timer not running'}
