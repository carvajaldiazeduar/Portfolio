from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import os

app = FastAPI()

CONVERSIONS = {
    'length': {
        'meter': 1.0, 'kilometer': 1000.0, 'centimeter': 0.01,
        'millimeter': 0.001, 'mile': 1609.344, 'yard': 0.9144,
        'foot': 0.3048, 'inch': 0.0254,
    },
    'weight': {
        'kilogram': 1.0, 'gram': 0.001, 'milligram': 0.000001,
        'pound': 0.453592, 'ounce': 0.0283495,
    },
    'temperature': {
        'celsius': 'celsius', 'fahrenheit': 'fahrenheit', 'kelvin': 'kelvin',
    },
}


class ConvertRequest(BaseModel):
    value: float
    from_unit: str
    to_unit: str


class ConvertResponse(BaseModel):
    result: float | None = None
    unit: str | None = None
    error: str | None = None


def _convert_temperature(value, from_unit, to_unit):
    if from_unit == to_unit:
        return value
    if from_unit == 'celsius':
        if to_unit == 'fahrenheit':
            return value * 9/5 + 32
        if to_unit == 'kelvin':
            return value + 273.15
    if from_unit == 'fahrenheit':
        if to_unit == 'celsius':
            return (value - 32) * 5/9
        if to_unit == 'kelvin':
            return (value - 32) * 5/9 + 273.15
    if from_unit == 'kelvin':
        if to_unit == 'celsius':
            return value - 273.15
        if to_unit == 'fahrenheit':
            return (value - 273.15) * 9/5 + 32
    return value


@app.get("/", response_class=HTMLResponse)
async def index():
    html_path = os.path.join(os.path.dirname(__file__), "static", "index.html")
    with open(html_path, encoding="utf-8") as f:
        return f.read()


@app.post("/api/convert", response_model=ConvertResponse)
async def convert(req: ConvertRequest):
    from_u = req.from_unit.lower()
    to_u = req.to_unit.lower()

    if from_u in CONVERSIONS['temperature'] and to_u in CONVERSIONS['temperature']:
        result = _convert_temperature(req.value, from_u, to_u)
        return ConvertResponse(result=result, unit=to_u)

    for category, units in CONVERSIONS.items():
        if isinstance(units, dict) and from_u in units and to_u in units:
            result = req.value * units[from_u] / units[to_u]
            return ConvertResponse(result=result, unit=to_u)

    return ConvertResponse(error="Unsupported conversion")
