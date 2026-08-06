import os
from flask import Flask, request, jsonify, render_template, send_from_directory
from storage.database_factory import create_adapter
from cache.cache_factory import create_cache

app = Flask(__name__)
db = create_adapter()
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))

MESSAGES_COLS = {
    "sender": "TEXT NOT NULL DEFAULT ''",
    "subject": "TEXT NOT NULL",
    "body": "TEXT DEFAULT ''",
    "read": "INTEGER DEFAULT 0",
    "created_at": "TIMESTAMP DEFAULT NOW()",
}
db.init_table("messages", MESSAGES_COLS)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/messages", methods=["GET"])
def list_messages():
    cached = cache.get("messages:all")
    if cached is not None:
        return jsonify(cached)
    rows = db.get_all("messages")
    cache.set("messages:all", rows, ttl=CACHE_TTL)
    return jsonify(rows)

@app.route("/api/messages", methods=["POST"])
def add_message():
    data = request.get_json()
    if not data or not data.get("subject"):
        return jsonify({"error": "Subject is required"}), 400
    msg = db.create("messages", {
        "sender": data.get("sender", ""),
        "subject": data["subject"],
        "body": data.get("body", ""),
    })
    cache.delete("messages:all")
    return jsonify(msg), 201

@app.route("/api/messages/<id>", methods=["GET"])
def get_message(id):
    cached = cache.get(f"message:{id}")
    if cached is not None:
        return jsonify(cached)
    msg = db.get_by_id("messages", id)
    if not msg:
        return jsonify({"error": "Not found"}), 404
    db.update("messages", id, {"read": 1})
    msg["read"] = True
    cache.set(f"message:{id}", msg, ttl=CACHE_TTL)
    cache.delete("messages:all")
    return jsonify(msg)

@app.route("/api/messages/<id>", methods=["DELETE"])
def delete_message(id):
    deleted = db.delete("messages", id)
    if not deleted:
        return jsonify({"error": "Not found"}), 404
    cache.delete("messages:all")
    cache.delete(f"message:{id}")
    return jsonify({"message": "Deleted"})

@app.route("/openapi.json")
def openapi_spec():
    return send_from_directory("static", "openapi.json")

@app.route("/swagger")
def swagger():
    return send_from_directory("static", "swagger.html")

if __name__ == "__main__":
    app.run(debug=True)
