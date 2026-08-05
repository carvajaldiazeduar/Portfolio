import json
import os
import urllib.request
from flask import Flask, jsonify, render_template, request

app = Flask(__name__)

DEFAULT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o-mini")
DEFAULT_TEMPERATURE = float(os.getenv("CHAT_TEMPERATURE", "0.7"))
DEFAULT_MAX_TOKENS = int(os.getenv("CHAT_MAX_TOKENS", "1024"))
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1").rstrip("/")


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
    try:
        result = complete_chat(data["messages"], model, temperature, max_tokens)
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


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
