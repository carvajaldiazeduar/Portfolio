import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

import pytest

os.environ["CACHE_TYPE"] = "local"
os.environ["JWT_SECRET"] = "test-secret"

from fastapi.testclient import TestClient

import config
import jwt_util
from cache import LocalCache, create_cache


@pytest.fixture(autouse=True)
def fresh_cache(monkeypatch):
    import main

    cache = LocalCache()
    monkeypatch.setattr(main, "cache", cache)
    yield cache


@pytest.fixture()
def client():
    from main import app

    with TestClient(app) as c:
        yield c


def admin_token():
    payload = {"id": 1, "username": "admin", "roles": ["admin"], "exp": int(__import__("time").time()) + 3600}
    return jwt_util.sign(payload, "test-secret")


def test_index_serves_html(client):
    resp = client.get("/")
    assert resp.status_code == 200


def test_swagger_redirects(client):
    resp = client.get("/swagger", follow_redirects=False)
    assert resp.status_code in (301, 302, 307)
    assert resp.headers.get("location") == "/swagger.html"


def test_health_returns_ok(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_login_valid_returns_token(client):
    resp = client.post("/auth/login", json={"username": "admin", "password": "admin"})
    assert resp.status_code == 200
    assert "token" in resp.json()


def test_login_invalid_returns_401(client):
    resp = client.post("/auth/login", json={"username": "wrong", "password": "wrong"})
    assert resp.status_code == 401


def test_login_missing_returns_400(client):
    resp = client.post("/auth/login", json={})
    assert resp.status_code == 400


def test_protected_route_without_token_returns_401(client):
    resp = client.get("/api/users")
    assert resp.status_code == 401
    assert resp.json()["error"] == "Missing or invalid Authorization header"


def test_protected_route_with_invalid_token_returns_401(client):
    resp = client.get("/api/users", headers={"Authorization": "Bearer not-a-valid-token"})
    assert resp.status_code == 401
    assert resp.json()["error"] == "Invalid or expired token"


def test_protected_route_with_valid_token_passes_auth(client, monkeypatch):
    class FakeResponse:
        status_code = 200
        headers = {"content-type": "application/json"}

        def json(self):
            return {"ok": True}

    async def fake_request(method, url, **kwargs):
        return FakeResponse()

    import httpx

    monkeypatch.setattr(httpx.AsyncClient, "request", staticmethod(fake_request))

    resp = client.get("/api/users", headers={"Authorization": "Bearer " + admin_token()})
    assert resp.status_code == 200


def test_rate_limiting_returns_429_when_exceeded(client, monkeypatch):
    class FakeResponse:
        status_code = 200
        headers = {"content-type": "application/json"}

        def json(self):
            return {"ok": True}

    async def fake_request(method, url, **kwargs):
        return FakeResponse()

    import httpx

    monkeypatch.setattr(httpx.AsyncClient, "request", staticmethod(fake_request))

    token = admin_token()
    allowed = 0
    last_status = 0
    for _ in range(55):
        resp = client.get("/api/users", headers={"Authorization": "Bearer " + token})
        if resp.status_code == 200:
            allowed += 1
        last_status = resp.status_code

    assert allowed == 50
    assert last_status == 429