import pytest
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from app import app

@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        with app.app_context():
            from app import contacts
            contacts.clear()
        yield client

def test_list_empty(client):
    rv = client.get("/api/contacts")
    assert rv.status_code == 200
    assert rv.get_json() == []

def test_add_contact(client):
    rv = client.post("/api/contacts", json={"name": "Alice", "phone": "123", "email": "a@b.com"})
    assert rv.status_code == 201
    data = rv.get_json()
    assert data["name"] == "Alice"

def test_add_contact_missing_name(client):
    rv = client.post("/api/contacts", json={"phone": "123"})
    assert rv.status_code == 400

def test_list_after_add(client):
    client.post("/api/contacts", json={"name": "Alice", "phone": "123", "email": "a@b.com"})
    rv = client.get("/api/contacts")
    assert len(rv.get_json()) == 1

def test_search_contacts(client):
    client.post("/api/contacts", json={"name": "Alice", "phone": "123", "email": "a@b.com"})
    client.post("/api/contacts", json={"name": "Bob", "phone": "456", "email": "b@c.com"})
    rv = client.get("/api/contacts/search?q=ali")
    data = rv.get_json()
    assert len(data) == 1
    assert data[0]["name"] == "Alice"

def test_delete_contact(client):
    client.post("/api/contacts", json={"name": "Alice", "phone": "123", "email": "a@b.com"})
    rv = client.delete("/api/contacts/0")
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
