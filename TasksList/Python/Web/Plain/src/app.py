import os
from flask import Flask, request, jsonify, render_template, send_from_directory
from storage.database_factory import create_adapter
from cache.cache_factory import create_cache

app = Flask(__name__)
db = create_adapter()
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))

TASKS_COLS = {
    "title": "TEXT NOT NULL",
    "description": "TEXT DEFAULT ''",
    "completed": "INTEGER DEFAULT 0",
    "created_at": "TIMESTAMP DEFAULT NOW()",
}
db.init_table("tasks", TASKS_COLS)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/tasks", methods=["GET"])
def list_tasks():
    cached = cache.get("tasks:all")
    if cached is not None:
        return jsonify(cached)
    rows = db.get_all("tasks")
    cache.set("tasks:all", rows, ttl=CACHE_TTL)
    return jsonify(rows)

@app.route("/api/tasks", methods=["POST"])
def add_task():
    data = request.get_json()
    if not data or not data.get("title"):
        return jsonify({"error": "Title is required"}), 400
    task = db.create("tasks", {
        "title": data["title"],
        "description": data.get("description", ""),
    })
    cache.delete("tasks:all")
    return jsonify(task), 201

@app.route("/api/tasks/<id>/complete", methods=["PUT"])
def complete_task(id):
    updated = db.update("tasks", id, {"completed": 1})
    if not updated:
        return jsonify({"error": "Task not found"}), 404
    cache.delete("tasks:all")
    return jsonify({"message": "Completed"})

@app.route("/api/tasks/<id>", methods=["DELETE"])
def delete_task(id):
    deleted = db.delete("tasks", id)
    if not deleted:
        return jsonify({"error": "Task not found"}), 404
    cache.delete("tasks:all")
    return jsonify({"message": "Deleted"})

@app.route("/openapi.json")
def openapi_spec():
    return send_from_directory("static", "openapi.json")

@app.route("/swagger")
def swagger():
    return send_from_directory("static", "swagger.html")

if __name__ == "__main__":
    app.run(debug=True)
