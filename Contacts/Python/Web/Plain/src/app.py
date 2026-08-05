import os
from flask import Flask, request, jsonify, render_template
from storage.database_factory import create_adapter
from cache.cache_factory import create_cache

app = Flask(__name__)
db = create_adapter()
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))

CONTACTS_COLS = {
    "name": "TEXT NOT NULL",
    "phone": "TEXT DEFAULT ''",
    "email": "TEXT DEFAULT ''",
}
db.init_table("contacts", CONTACTS_COLS)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/contacts", methods=["GET"])
def list_contacts():
    cached = cache.get("contacts:all")
    if cached is not None:
        return jsonify(cached)
    rows = db.get_all("contacts")
    cache.set("contacts:all", rows, ttl=CACHE_TTL)
    return jsonify(rows)

@app.route("/api/contacts", methods=["POST"])
def add_contact():
    data = request.get_json()
    if not data or not data.get("name"):
        return jsonify({"error": "Name is required"}), 400
    contact = db.create("contacts", {
        "name": data["name"],
        "phone": data.get("phone", ""),
        "email": data.get("email", ""),
    })
    cache.delete("contacts:all")
    return jsonify(contact), 201

@app.route("/api/contacts/search", methods=["GET"])
def search_contacts():
    q = request.args.get("q", "").lower()
    cached = cache.get(f"contacts:search:{q}")
    if cached is not None:
        return jsonify(cached)
    rows = db.search("contacts", "name", q)
    cache.set(f"contacts:search:{q}", rows, ttl=CACHE_TTL)
    return jsonify(rows)

@app.route("/api/contacts/<id>", methods=["DELETE"])
def delete_contact(id):
    deleted = db.delete("contacts", id)
    if not deleted:
        return jsonify({"error": "Not found"}), 404
    cache.delete("contacts:all")
    return jsonify({"message": "Deleted"})

@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not found"}), 404

if __name__ == "__main__":
    app.run(debug=True)
