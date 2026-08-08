import sys
import os
import sqlite3
import tempfile
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
os.environ["DB_DRIVER"] = "sqlite"
os.environ["DB_FILE"] = os.path.join(tempfile.gettempdir(), "test-contacts.db")
os.environ["CACHE_TYPE"] = "local"

import pytest
from app import app


@pytest.fixture
def client():
    conn = sqlite3.connect(os.environ["DB_FILE"])
    conn.execute("DELETE FROM contacts")
    conn.commit()
    conn.close()
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_add_contact(client):
    rv = client.post("/api/contacts", json={"name": "Alice", "phone": "123-4567", "email": "a@b.com"})
    assert rv.status_code == 201
    data = rv.get_json()
    assert data["name"] == "Alice"


def test_add_contact_strips_input(client):
    rv = client.post("/api/contacts", json={"name": "  Alice  ", "phone": " 123-4567 ", "email": " a@b.com "})
    assert rv.status_code == 201
    data = rv.get_json()
    assert data["name"] == "Alice"
    assert data["phone"] == "123-4567"
    assert data["email"] == "a@b.com"


def test_add_contact_invalid_email(client):
    rv = client.post("/api/contacts", json={"name": "Alice", "phone": "123-4567", "email": "not-an-email"})
    assert rv.status_code == 400
    data = rv.get_json()
    assert "email" in data["errors"]
    assert data["errors"]["email"] == "Invalid email format"


def test_add_contact_invalid_phone(client):
    rv = client.post("/api/contacts", json={"name": "Alice", "phone": "abc", "email": "a@b.com"})
    assert rv.status_code == 400
    data = rv.get_json()
    assert "phone" in data["errors"]


def test_add_contact_missing_name(client):
    rv = client.post("/api/contacts", json={"phone": "123-4567", "email": "a@b.com"})
    assert rv.status_code == 400
    data = rv.get_json()
    assert "name" in data["errors"]
    assert data["errors"]["name"] == "Name is required"


def test_add_contact_short_name(client):
    rv = client.post("/api/contacts", json={"name": "A", "phone": "123-4567", "email": "a@b.com"})
    assert rv.status_code == 400
    data = rv.get_json()
    assert "name" in data["errors"]


def test_add_contact_invalid_not_stored(client):
    client.post("/api/contacts", json={"name": "Alice", "phone": "abc", "email": "a@b.com"})
    rv = client.get("/api/contacts")
    assert rv.get_json() == []


def test_index_html(client):
    rv = client.get("/")
    assert rv.status_code == 200
    assert b"Contact Manager" in rv.data
