import os
import time
from datetime import datetime, timezone
from pathlib import Path

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

import config
from cache import create_cache
from jwt_util import sign, verify

BASE_DIR = Path(__file__).resolve().parent
STATIC_DIR = BASE_DIR / "static"

app = FastAPI(title="API Gateway", version="1.0.0")

cache = create_cache()


class LoginBody(BaseModel):
    username: str = None
    password: str = None


# ── public UI / docs ──────────────────────────────────────────────────────
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")


@app.get("/")
def index():
    return FileResponse(STATIC_DIR / "index.html")


@app.get("/styles.css")
def styles():
    return FileResponse(STATIC_DIR / "styles.css")


@app.get("/app.js")
def app_js():
    return FileResponse(STATIC_DIR / "app.js")


@app.get("/openapi.json")
def openapi():
    return FileResponse(STATIC_DIR / "openapi.json")


@app.get("/swagger")
def swagger():
    return RedirectResponse("/swagger.html")


@app.get("/swagger.html")
def swagger_ui():
    return FileResponse(STATIC_DIR / "swagger.html")


@app.get("/health")
def health():
    return {"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}


# ── auth ──────────────────────────────────────────────────────────────────
@app.post("/auth/login")
def login(body: LoginBody):
    if not body.username or not body.password:
        return JSONResponse(status_code=400, content={"error": "Username and password required"})

    if body.username == "admin" and body.password == "admin":
        payload = {
            "id": 1,
            "username": "admin",
            "roles": ["admin"],
            "exp": int(time.time()) + 3600,
        }
        return {"token": sign(payload, config.JWT_SECRET), "expiresIn": "1h"}

    if body.username == "user" and body.password == "user":
        payload = {
            "id": 2,
            "username": "user",
            "roles": ["user"],
            "exp": int(time.time()) + 3600,
        }
        return {"token": sign(payload, config.JWT_SECRET), "expiresIn": "1h"}

    return JSONResponse(status_code=401, content={"error": "Invalid credentials"})


# ── middleware chain: auth -> rate limit ─────────────────────────────────
@app.middleware("http")
async def gateway_middleware(request: Request, call_next):
    path = request.url.path

    if not path.startswith("/api/"):
        return await call_next(request)

    # 1. Auth
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return JSONResponse(status_code=401, content={"error": "Missing or invalid Authorization header"})
    token = auth_header[7:]
    user = verify(token, config.JWT_SECRET)
    if user is None:
        return JSONResponse(status_code=401, content={"error": "Invalid or expired token"})

    # 2. Rate limit
    prefix = resolve_route(path)
    limit_cfg = config.ROUTE_LIMITS.get(prefix, {
        "limit": config.RATE_LIMIT_DEFAULT,
        "window": config.RATE_LIMIT_WINDOW,
    })
    limit = limit_cfg["limit"]
    window_sec = limit_cfg["window"]
    client_ip = request.client.host if request.client else "unknown"
    key = f"ratelimit:{path}:{client_ip}"

    current = cache.increment(key, window_sec)
    remaining = max(0, limit - int(current))
    headers = {
        "X-RateLimit-Limit": str(limit),
        "X-RateLimit-Remaining": str(remaining),
        "X-RateLimit-Reset": str(int(time.time()) + window_sec),
    }

    if int(current) > limit:
        return JSONResponse(
            status_code=429,
            content={"error": f"Rate limit exceeded. Limit: {limit} requests per {window_sec}s"},
            headers=headers,
        )

    request.state.user = user
    response = await call_next(request)
    for key_, value in headers.items():
        response.headers[key_] = value
    return response


def resolve_route(path: str) -> str:
    for prefix in ("/api/users", "/api/orders", "/api/products"):
        if path.startswith(prefix):
            return prefix
    return path


# ── proxy: forwarding to backend services ────────────────────────────────
UPSTREAMS = {
    "/api/users": config.SERVICES["users"],
    "/api/orders": config.SERVICES["orders"],
    "/api/products": config.SERVICES["products"],
}


@app.api_route("/api/{service}/{full_path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"])
async def proxy(service: str, full_path: str, request: Request):
    prefix = f"/api/{service}"
    upstream = UPSTREAMS.get(prefix)
    if not upstream:
        return JSONResponse(status_code=404, content={"error": "Unknown service"})

    remainder = full_path if full_path else ""
    target = upstream.rstrip("/") + "/" + remainder
    if request.url.query:
        target += "?" + request.url.query

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.request(
                request.method,
                target,
                content=await request.body(),
                headers={
                    k: v for k, v in request.headers.items()
                    if k.lower() not in ("host", "content-length")
                },
            )
        return JSONResponse(
            status_code=resp.status_code,
            content=resp.json() if resp.headers.get("content-type", "").startswith("application/json") else {"text": resp.text},
        )
    except Exception:
        return JSONResponse(status_code=502, content={"error": "Bad Gateway", "message": "Upstream service unavailable"})