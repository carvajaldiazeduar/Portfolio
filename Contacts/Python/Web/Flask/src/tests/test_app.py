import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
os.environ["DB_DRIVER"] = "sqlite"
os.environ["DB_FILE"] = "test-contacts.db"
os.environ["CACHE_TYPE"] = "local"

import pytest
from app import app, db


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.app_context():
        db.drop_all()
        db.create_all()
    with app.test_client() as client:
        yield client


def test_list_empty(client):
    rv = client.get("/api/contacts")
    assert rv.status_code == 200
    assert rv.get_json() == []


def test_add_contact(client):
    rv = client.post("/api/contacts", json={"name": "Alice", "phone": "123-4567", "email": "a@b.com"})
    assert rv.status_code == 201
    data = rv.get_json()
    assert data["name"] == "Alice"


def test_add_contact_missing_name(client):
    rv = client.post("/api/contacts", json={"phone": "123-4567"})
    assert rv.status_code == 400
    data = rv.get_json()
    assert "name" in data["errors"]
    assert data["errors"]["name"] == "Name is required"


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
    assert data["errors"]["phone"] == "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"


def test_add_contact_short_name(client):
    rv = client.post("/api/contacts", json={"name": "A", "phone": "123-4567", "email": "a@b.com"})
    assert rv.status_code == 400
    data = rv.get_json()
    assert "name" in data["errors"]


def test_add_contact_invalid_not_stored(client):
    client.post("/api/contacts", json={"name": "Alice", "phone": "abc", "email": "a@b.com"})
    rv = client.get("/api/contacts")
    assert rv.get_json() == []


def test_list_after_add(client):
    client.post("/api/contacts", json={"name": "Alice", "phone": "123-4567", "email": "a@b.com"})
    rv = client.get("/api/contacts")
    assert len(rv.get_json()) == 1


def test_search_contacts(client):
    client.post("/api/contacts", json={"name": "Alice", "phone": "123-4567", "email": "a@b.com"})
    client.post("/api/contacts", json={"name": "Bob", "phone": "987-6543", "email": "b@c.com"})
    rv = client.get("/api/contacts/search?q=ali")
    data = rv.get_json()
    assert len(data) == 1
    assert data[0]["name"] == "Alice"


def test_delete_contact(client):
    post = client.post("/api/contacts", json={"name": "Alice", "phone": "123-4567", "email": "a@b.com"})
    cid = post.get_json()["id"]
    rv = client.delete(f"/api/contacts/{cid}")
    assert rv.status_code == 200
    rv = client.get("/api/contacts")
    assert rv.get_json() == []


def test_delete_invalid_index(client):
    rv = client.delete("/api/contacts/99")
    assert rv.status_code == 404


def test_index_html(client):
    rv = client.get("/")
    assert rv.status_code == 200
    assert b"Contact Manager" in rv.data
