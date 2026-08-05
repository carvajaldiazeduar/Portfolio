import os
from flask import Flask, request, jsonify, render_template
from config import DATABASE_URL
from models import db, Task
from cache import create_cache

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = DATABASE_URL
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db.init_app(app)

cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))

with app.app_context():
    db.create_all()

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/tasks", methods=["GET"])
def get_tasks():
    cached = cache.get("tasks:all")
    if cached is not None:
        return jsonify(cached)
    tasks = Task.query.order_by(Task.id).all()
    data = [t.to_dict() for t in tasks]
    cache.set("tasks:all", data, ttl=CACHE_TTL)
    return jsonify(data)

@app.route("/api/tasks", methods=["POST"])
def add_task():
    data = request.get_json(force=True)
    title = data.get("title", "").strip()
    description = data.get("description", "").strip()
    if not title:
        return jsonify({"error": "Title is required"}), 400
    task = Task(title=title, description=description)
    db.session.add(task)
    db.session.commit()
    cache.delete("tasks:all")
    return jsonify(task.to_dict()), 201

@app.route("/api/tasks/<int:task_id>/complete", methods=["PUT"])
def complete_task(task_id):
    task = Task.query.get(task_id)
    if task is None:
        return jsonify({"error": "Task not found"}), 404
    task.completed = True
    db.session.commit()
    cache.delete("tasks:all")
    return jsonify(task.to_dict())

@app.route("/api/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    task = Task.query.get(task_id)
    if task is None:
        return jsonify({"error": "Task not found"}), 404
    db.session.delete(task)
    db.session.commit()
    cache.delete("tasks:all")
    return jsonify({"result": "deleted"})

if __name__ == "__main__":
    app.run(debug=True)
