import os
import secrets
import string
from flask import Flask, request, jsonify, render_template
from storage.database_factory import create_adapter
from cache.cache_factory import create_cache

app = Flask(__name__)
db = create_adapter()
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))

PASSWORD_ENTRIES_COLS = {
    "password": "TEXT NOT NULL",
    "length": "INTEGER DEFAULT 16",
    "created_at": "TIMESTAMP DEFAULT NOW()",
}
db.init_table("password_entries", PASSWORD_ENTRIES_COLS)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/generate", methods=["POST"])
def generate():
    data = request.get_json(silent=True) or {}
    length = data.get("length", 16)
    use_upper = data.get("use_upper", True)
    use_lower = data.get("use_lower", True)
    use_digits = data.get("use_digits", True)
    use_symbols = data.get("use_symbols", False)
    chars = ""
    if use_upper:
        chars += string.ascii_uppercase
    if use_lower:
        chars += string.ascii_lowercase
    if use_digits:
        chars += string.digits
    if use_symbols:
        chars += "!@#$%^&*()_+-=[]{}|;:,.<>?"
    if not chars:
        return jsonify({"error": "Select at least one character type"}), 400
    password = "".join(secrets.choice(chars) for _ in range(length))
    db.create("password_entries", {
        "password": password,
        "length": length,
    })
    cache.delete("passwords:recent")
    return jsonify({"password": password})

@app.route("/api/passwords", methods=["GET"])
def history():
    cached = cache.get("passwords:recent")
    if cached is not None:
        return jsonify(cached)
    rows = db.get_all("password_entries")
    cache.set("passwords:recent", rows, ttl=CACHE_TTL)
    return jsonify(rows)

if __name__ == "__main__":
    app.run(debug=True)
