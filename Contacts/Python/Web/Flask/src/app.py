import os
import re
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

NAME_RE = re.compile(r"^[A-Za-zÀ-ÿ' .-]+$")
PHONE_RE = re.compile(r"^[0-9 +().-]{7,20}$")
EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$")

NAME_REQUIRED = "Name is required"
PHONE_REQUIRED = "Phone is required"
EMAIL_REQUIRED = "Email is required"
NAME_FORMAT = "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)"
PHONE_FORMAT = "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"
EMAIL_FORMAT = "Invalid email format"

def validate_contact(data):
    errors = {}
    name = (data.get("name") or "").strip() if data else ""
    phone = (data.get("phone") or "").strip() if data else ""
    email = (data.get("email") or "").strip() if data else ""
    if not name:
        errors["name"] = NAME_REQUIRED
    elif not (2 <= len(name) <= 100) or not NAME_RE.match(name):
        errors["name"] = NAME_FORMAT
    if not phone:
        errors["phone"] = PHONE_REQUIRED
    elif not PHONE_RE.match(phone):
        errors["phone"] = PHONE_FORMAT
    if not email:
        errors["email"] = EMAIL_REQUIRED
    elif not EMAIL_RE.match(email):
        errors["email"] = EMAIL_FORMAT
    return errors, {"name": name, "phone": phone, "email": email}

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
    data = request.get_json(silent=True) or {}
    errors, values = validate_contact(data)
    if errors:
        return jsonify({"errors": errors}), 400
    contact = Contact(name=values["name"], phone=values["phone"], email=values["email"])
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
