import pytest
import app as chat_app


@pytest.fixture
def client(monkeypatch):
    chat_app.app.config["TESTING"] = True
    with chat_app.app.test_client() as client:
        yield client


def _fake_complete(messages, model, temperature, max_tokens):
    return {
        "id": "chatcmpl-test",
        "model": model,
        "choices": [{"message": {"role": "assistant", "content": "Hello!"}}],
        "usage": {"prompt_tokens": 5, "completion_tokens": 3, "total_tokens": 8},
    }


def test_index(client):
    response = client.get("/")
    assert response.status_code == 200


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_chat_valid_message(client, monkeypatch):
    monkeypatch.setattr(chat_app, "complete_chat", _fake_complete)
    response = client.post("/api/chat", json={"messages": [{"role": "user", "content": "Hi"}]})
    assert response.status_code == 200
    data = response.get_json()
    assert data["choices"][0]["role"] == "assistant"
    assert data["choices"][0]["content"] == "Hello!"
    assert data["id"] == "chatcmpl-test"
    assert data["usage"]["total_tokens"] == 8


def test_chat_client_overrides_model(client, monkeypatch):
    captured = {}

    def _capture(messages, model, temperature, max_tokens):
        captured["model"] = model
        captured["temperature"] = temperature
        captured["max_tokens"] = max_tokens
        return _fake_complete(messages, model, temperature, max_tokens)

    monkeypatch.setattr(chat_app, "complete_chat", _capture)
    response = client.post(
        "/api/chat",
        json={
            "messages": [{"role": "user", "content": "Hi"}],
            "model": "gpt-4-turbo",
            "temperature": 0.2,
            "max_tokens": 500,
        },
    )
    assert response.status_code == 200
    assert captured["model"] == "gpt-4-turbo"
    assert captured["temperature"] == 0.2
    assert captured["max_tokens"] == 500


def test_chat_empty_messages(client):
    response = client.post("/api/chat", json={"messages": []})
    assert response.status_code == 400


def test_chat_provider_failure(client, monkeypatch):
    def _boom(messages, model, temperature, max_tokens):
        raise Exception("upstream provider failed")

    monkeypatch.setattr(chat_app, "complete_chat", _boom)
    response = client.post("/api/chat", json={"messages": [{"role": "user", "content": "Hi"}]})
    assert response.status_code == 502
