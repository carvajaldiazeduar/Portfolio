import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
os.environ["DB_DRIVER"] = "sqlite"
os.environ["DB_FILE"] = "test-passwords.db"
os.environ["CACHE_TYPE"] = "local"

import pytest
from app import app, db, generate_password, UPPERCASE, LOWERCASE, DIGITS, SYMBOLS


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.app_context():
        db.drop_all()
        db.create_all()
    with app.test_client() as client:
        yield client


class TestGeneratePassword:
    def test_default_length(self):
        pw = generate_password()
        assert len(pw) == 16

    def test_custom_length(self):
        pw = generate_password(length=24)
        assert len(pw) == 24

    def test_uppercase_present(self):
        pw = generate_password(use_upper=True, use_lower=False, use_digits=False, use_symbols=False)
        assert any(c in UPPERCASE for c in pw)

    def test_no_uppercase(self):
        pw = generate_password(use_upper=False)
        assert not any(c in UPPERCASE for c in pw)

    def test_no_symbols(self):
        pw = generate_password(use_symbols=False)
        assert not any(c in SYMBOLS for c in pw)

    def test_all_disabled_raises(self):
        with pytest.raises(ValueError):
            generate_password(use_upper=False, use_lower=False, use_digits=False, use_symbols=False)

    def test_length_zero_raises(self):
        with pytest.raises(ValueError):
            generate_password(length=0)

    def test_at_least_one_from_each_enabled(self):
        pw = generate_password(length=20)
        assert any(c in UPPERCASE for c in pw)
        assert any(c in LOWERCASE for c in pw)
        assert any(c in DIGITS for c in pw)
        assert any(c in SYMBOLS for c in pw)


class TestAPI:
    def test_generate_default(self, client):
        resp = client.post("/api/generate", json={})
        assert resp.status_code == 200
        data = resp.get_json()
        assert len(data["password"]) == 16

    def test_generate_custom_length(self, client):
        resp = client.post("/api/generate", json={"length": 24})
        assert resp.status_code == 200
        data = resp.get_json()
        assert len(data["password"]) == 24

    def test_generate_no_uppercase(self, client):
        resp = client.post("/api/generate", json={"use_upper": False})
        assert resp.status_code == 200
        data = resp.get_json()
        assert not any(c in UPPERCASE for c in data["password"])

    def test_generate_no_symbols(self, client):
        resp = client.post("/api/generate", json={"use_symbols": False})
        assert resp.status_code == 200
        data = resp.get_json()
        assert not any(c in SYMBOLS for c in data["password"])

    def test_generate_error_no_categories(self, client):
        resp = client.post("/api/generate", json={
            "use_upper": False, "use_lower": False, "use_digits": False, "use_symbols": False
        })
        assert resp.status_code == 400
        data = resp.get_json()
        assert "error" in data

    def test_generate_error_bad_length(self, client):
        resp = client.post("/api/generate", json={"length": -1})
        assert resp.status_code == 400
        data = resp.get_json()
        assert "error" in data

    def test_generate_invalid_json(self, client):
        resp = client.post("/api/generate", data="not json", content_type="application/json")
        assert resp.status_code == 200

    def test_index(self, client):
        resp = client.get("/")
        assert resp.status_code == 200
        assert b"Password Generator" in resp.data
