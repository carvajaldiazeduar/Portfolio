import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from app import app
import json

def test_index():
    with app.test_client() as client:
        resp = client.get("/")
        assert resp.status_code == 200
        assert b"Unit Converter" in resp.data

def test_api_categories():
    with app.test_client() as client:
        resp = client.get("/api/categories")
        assert resp.status_code == 200
        data = json.loads(resp.data)
        assert "length" in data
        assert "weight" in data
        assert "temperature" in data

def test_api_convert_length():
    with app.test_client() as client:
        resp = client.post("/api/convert", json={"value": 1, "from": "m", "to": "cm"})
        assert resp.status_code == 200
        data = json.loads(resp.data)
        assert abs(data["result"] - 100) < 0.001

def test_api_convert_weight():
    with app.test_client() as client:
        resp = client.post("/api/convert", json={"value": 1, "from": "kg", "to": "g"})
        assert resp.status_code == 200
        data = json.loads(resp.data)
        assert abs(data["result"] - 1000) < 0.001

def test_api_convert_temperature():
    with app.test_client() as client:
        resp = client.post("/api/convert", json={"value": 0, "from": "C", "to": "F"})
        assert resp.status_code == 200
        data = json.loads(resp.data)
        assert abs(data["result"] - 32) < 0.001

def test_api_convert_invalid_unit():
    with app.test_client() as client:
        resp = client.post("/api/convert", json={"value": 1, "from": "m", "to": "kg"})
        assert resp.status_code == 400
        data = json.loads(resp.data)
        assert "error" in data

def test_api_convert_incompatible():
    with app.test_client() as client:
        resp = client.post("/api/convert", json={"value": 1, "from": "m", "to": "kg"})
        assert resp.status_code == 400

def test_api_convert_missing_fields():
    with app.test_client() as client:
        resp = client.post("/api/convert", json={"value": 1})
        assert resp.status_code == 400
