import os
from flask import Flask, request, jsonify, render_template, send_from_directory
from config import DATABASE_URL
from models import db, Contact
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

@app.route("/api/contacts", methods=["GET"])
def list_contacts():
    cached = cache.get("contacts:all")
    if cached is not None:
        return jsonify(cached)
    contacts = Contact.query.order_by(Contact.id).all()
    data = [c.to_dict() for c in contacts]
    cache.set("contacts:all", data, ttl=CACHE_TTL)
    return jsonify(data)

@app.route("/api/contacts", methods=["POST"])
def add_contact():
    data = request.get_json()
    if not data or not data.get("name"):
        return jsonify({"error": "Name is required"}), 400
    contact = Contact(name=data["name"], phone=data.get("phone", ""), email=data.get("email", ""))
    db.session.add(contact)
    db.session.commit()
    cache.delete("contacts:all")
    return jsonify(contact.to_dict()), 201

@app.route("/api/contacts/search", methods=["GET"])
def search_contacts():
    query = request.args.get("q", "").lower()
    cached = cache.get(f"contacts:search:{query}")
    if cached is not None:
        return jsonify(cached)
    results = Contact.query.filter(Contact.name.ilike(f"%{query}%")).all()
    data = [c.to_dict() for c in results]
    cache.set(f"contacts:search:{query}", data, ttl=CACHE_TTL)
    return jsonify(data)

@app.route("/api/contacts/<int:index>", methods=["DELETE"])
def delete_contact(index):
    contact = Contact.query.get(index)
    if contact is None:
        return jsonify({"error": "Not found"}), 404
    db.session.delete(contact)
    db.session.commit()
    cache.delete("contacts:all")
    return jsonify(contact.to_dict())

@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not found"}), 404

@app.route("/openapi.json")
def openapi_spec():
    return send_from_directory("static", "openapi.json")

@app.route("/swagger")
def swagger():
    return send_from_directory("static", "swagger.html")

if __name__ == "__main__":
    app.run(debug=True)
