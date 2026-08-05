from flask import Flask, request, jsonify, render_template
from config import DATABASE_URL
from models import db, Message
from cache import create_cache

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = DATABASE_URL
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db.init_app(app)

cache = create_cache()
CACHE_TTL = 300

with app.app_context():
    db.create_all()

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/messages", methods=["GET"])
def list_messages():
    cached = cache.get("messages:all")
    if cached is not None:
        return jsonify(cached)
    msgs = Message.query.order_by(Message.id).all()
    data = [m.to_dict() for m in msgs]
    cache.set("messages:all", data, ttl=CACHE_TTL)
    return jsonify(data)

@app.route("/api/messages", methods=["POST"])
def send_message():
    data = request.get_json()
    if not data or not data.get("from") or not data.get("subject"):
        return jsonify({"error": "from and subject are required"}), 400
    msg = Message(sender=data["from"], subject=data["subject"], body=data.get("body", ""))
    db.session.add(msg)
    db.session.commit()
    cache.delete("messages:all")
    return jsonify(msg.to_dict()), 201

@app.route("/api/messages/<int:id>", methods=["GET"])
def read_message(id):
    cached = cache.get(f"message:{id}")
    if cached is not None:
        return jsonify(cached)
    msg = Message.query.get(id)
    if msg is None:
        return jsonify({"error": "not found"}), 404
    msg.read = True
    db.session.commit()
    data = msg.to_dict()
    cache.set(f"message:{id}", data, ttl=CACHE_TTL)
    cache.delete("messages:all")
    return jsonify(data)

@app.route("/api/messages/<int:id>", methods=["DELETE"])
def delete_message(id):
    msg = Message.query.get(id)
    if msg is None:
        return jsonify({"error": "not found"}), 404
    db.session.delete(msg)
    db.session.commit()
    cache.delete("messages:all")
    cache.delete(f"message:{id}")
    return "", 204

if __name__ == "__main__":
    app.run(debug=True)
