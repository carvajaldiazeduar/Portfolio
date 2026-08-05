from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import os

app = FastAPI()


class CalculateRequest(BaseModel):
    a: float
    b: float
    operator: str


class CalculateResponse(BaseModel):
    result: float | None = None
    error: str | None = None


@app.get("/", response_class=HTMLResponse)
async def index():
    html_path = os.path.join(os.path.dirname(__file__), "static", "index.html")
    with open(html_path, encoding="utf-8") as f:
        return f.read()


@app.post("/api/calculate", response_model=CalculateResponse)
async def calculate(req: CalculateRequest):
    if req.operator == "add":
        result = req.a + req.b
    elif req.operator == "subtract":
        result = req.a - req.b
    elif req.operator == "multiply":
        result = req.a * req.b
    elif req.operator == "divide":
        if req.b == 0:
            return CalculateResponse(error="Division by zero")
        result = req.a / req.b
    else:
        return CalculateResponse(error=f"Unknown operator: {req.operator}")

    return CalculateResponse(result=result)
