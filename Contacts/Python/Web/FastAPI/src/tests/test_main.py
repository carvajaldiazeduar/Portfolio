import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
os.environ["DB_DRIVER"] = "sqlite"
os.environ["DB_FILE"] = "/tmp/test-fastapi.db"
os.environ["CACHE_TYPE"] = "local"

import pytest
from fastapi.testclient import TestClient
from main import app


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


def test_add_contact(client):
    rv = client.post("/api/contacts", json={"name": "Alice", "phone": "123-4567", "email": "a@b.com"})
    assert rv.status_code == 201
    assert rv.json()["name"] == "Alice"


def test_add_contact_strips_input(client):
    rv = client.post("/api/contacts", json={"name": "  Alice  ", "phone": " 123-4567 ", "email": " a@b.com "})
    assert rv.status_code == 201
    data = rv.json()
    assert data["name"] == "Alice"
    assert data["phone"] == "123-4567"
    assert data["email"] == "a@b.com"


def test_add_contact_invalid_email(client):
    rv = client.post("/api/contacts", json={"name": "Alice", "phone": "123-4567", "email": "not-an-email"})
    assert rv.status_code == 400
    body = rv.json()
    assert "email" in body["errors"]
    assert body["errors"]["email"] == "Invalid email format"


def test_add_contact_invalid_phone(client):
    rv = client.post("/api/contacts", json={"name": "Alice", "phone": "abc", "email": "a@b.com"})
    assert rv.status_code == 400
    body = rv.json()
    assert "phone" in body["errors"]
    assert body["errors"]["phone"] == "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"


def test_add_contact_missing_name(client):
    rv = client.post("/api/contacts", json={"phone": "123-4567", "email": "a@b.com"})
    assert rv.status_code == 400
    body = rv.json()
    assert "name" in body["errors"]
    assert body["errors"]["name"] == "Name is required"


def test_add_contact_short_name(client):
    rv = client.post("/api/contacts", json={"name": "A", "phone": "123-4567", "email": "a@b.com"})
    assert rv.status_code == 400
    body = rv.json()
    assert "name" in body["errors"]


def test_add_contact_missing_all(client):
    rv = client.post("/api/contacts", json={})
    assert rv.status_code == 400
    body = rv.json()
    assert set(body["errors"].keys()) == {"name", "phone", "email"}


def test_index_html(client):
    rv = client.get("/")
    assert rv.status_code == 200
    assert "Contacts" in rv.text
