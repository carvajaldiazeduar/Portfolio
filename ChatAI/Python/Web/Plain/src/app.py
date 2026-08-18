import json
import os
import urllib.parse
import urllib.request
from flask import Flask, jsonify, render_template, request, send_from_directory

app = Flask(__name__)

DEFAULT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o-mini")
DEFAULT_TEMPERATURE = float(os.getenv("CHAT_TEMPERATURE", "0.7"))
DEFAULT_MAX_TOKENS = int(os.getenv("CHAT_MAX_TOKENS", "1024"))
CHAT_TIMEOUT_MS = int(os.getenv("CHAT_TIMEOUT_MS", "30000"))
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1").rstrip("/")
RAG_ENABLED = os.getenv("RAG_ENABLED", "").lower() in ("1", "true", "yes")
RAG_SEARCH_URL = os.getenv("RAG_SEARCH_URL", "http://semantic-search:5000/api/search")
RAG_TOP_K = int(os.getenv("RAG_TOP_K", "3"))


def retrieve_context(query):
    url = f"{RAG_SEARCH_URL}?q={urllib.parse.quote(query)}&k={RAG_TOP_K}"
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=CHAT_TIMEOUT_MS / 1000) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    return [r.get("document", "") for r in data.get("results", []) if r.get("document")]


def complete_chat(messages, model, temperature, max_tokens):
    payload = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
    }
    req = urllib.request.Request(
        f"{OPENAI_BASE_URL}/chat/completions",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    if OPENAI_API_KEY:
        req.add_header("Authorization", f"Bearer {OPENAI_API_KEY}")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/health")
def health():
    return jsonify({"status": "ok"})


@app.route("/api/chat", methods=["POST"])
def chat():
    data = request.get_json(silent=True)
    if not data or not data.get("messages"):
        return jsonify({"error": "Messages must not be empty"}), 400
    model = data.get("model") or DEFAULT_MODEL
    temperature = data.get("temperature") if data.get("temperature") is not None else DEFAULT_TEMPERATURE
    max_tokens = data.get("max_tokens") if data.get("max_tokens") is not None else DEFAULT_MAX_TOKENS
    messages = data["messages"]
    if RAG_ENABLED:
        last_user = next((m["content"] for m in reversed(messages) if m.get("role") == "user"), None)
        if last_user:
            try:
                documents = retrieve_context(last_user)
            except Exception as exc:
                app.logger.warning("RAG retrieval failed: %s", exc)
                documents = []
            if documents:
                context = "Use the following context to answer the user's question:\n\n" + "\n".join(
                    f"- {d}" for d in documents
                )
                messages = [{"role": "system", "content": context}] + messages
    try:
        result = complete_chat(messages, model, temperature, max_tokens)
    except Exception as exc:
        return jsonify({"error": str(exc)}), 502
    choices = [
        {
            "role": c.get("message", {}).get("role", "assistant"),
            "content": c.get("message", {}).get("content", ""),
        }
        for c in result.get("choices", [])
    ]
    usage = result.get("usage") or {}
    return jsonify(
        {
            "id": result.get("id", ""),
            "model": result.get("model", model),
            "choices": choices,
            "usage": {
                "prompt_tokens": usage.get("prompt_tokens", 0),
                "completion_tokens": usage.get("completion_tokens", 0),
                "total_tokens": usage.get("total_tokens", 0),
            },
        }
    )


@app.route("/openapi.json")
def openapi_spec():
    return send_from_directory("static", "openapi.json")


@app.route("/swagger")
def swagger():
    return send_from_directory("static", "swagger.html")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
