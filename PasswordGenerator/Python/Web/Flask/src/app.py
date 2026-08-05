import os
import random
from flask import Flask, request, jsonify, render_template
from config import DATABASE_URL
from models import db, PasswordEntry
from cache import create_cache

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = DATABASE_URL
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db.init_app(app)

cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))

UPPERCASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
LOWERCASE = "abcdefghijklmnopqrstuvwxyz"
DIGITS = "0123456789"
SYMBOLS = "!@#$%^&*()_+-=[]{}|;:,.<>?"

with app.app_context():
    db.create_all()

def generate_password(length=16, use_upper=True, use_lower=True, use_digits=True, use_symbols=True):
    if length < 1:
        raise ValueError("Password length must be at least 1")
    categories = []
    if use_upper:
        categories.append(UPPERCASE)
    if use_lower:
        categories.append(LOWERCASE)
    if use_digits:
        categories.append(DIGITS)
    if use_symbols:
        categories.append(SYMBOLS)
    if not categories:
        raise ValueError("At least one character category must be enabled")
    if length < len(categories):
        raise ValueError(f"Password length must be at least {len(categories)} when {len(categories)} categories are enabled")
    password = [random.choice(cat) for cat in categories]
    all_chars = "".join(categories)
    password.extend(random.choice(all_chars) for _ in range(length - len(categories)))
    random.shuffle(password)
    return "".join(password)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/generate", methods=["POST"])
def api_generate():
    data = request.get_json(silent=True) or {}
    try:
        length = int(data.get("length", 16))
    except (ValueError, TypeError):
        return jsonify({"error": "Invalid length"}), 400
    use_upper = data.get("use_upper", True)
    use_lower = data.get("use_lower", True)
    use_digits = data.get("use_digits", True)
    use_symbols = data.get("use_symbols", True)
    use_upper = bool(use_upper) if use_upper in (True, False) else str(use_upper).lower() == "true"
    use_lower = bool(use_lower) if use_lower in (True, False) else str(use_lower).lower() == "true"
    use_digits = bool(use_digits) if use_digits in (True, False) else str(use_digits).lower() == "true"
    use_symbols = bool(use_symbols) if use_symbols in (True, False) else str(use_symbols).lower() == "true"
    try:
        password = generate_password(length, use_upper, use_lower, use_digits, use_symbols)
        entry = PasswordEntry(password=password, length=length)
        db.session.add(entry)
        db.session.commit()
        cache.delete("passwords:recent")
        return jsonify({"password": password, "id": entry.id})
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

@app.route("/api/passwords", methods=["GET"])
def list_passwords():
    cached = cache.get("passwords:recent")
    if cached is not None:
        return jsonify(cached)
    entries = PasswordEntry.query.order_by(PasswordEntry.id.desc()).limit(50).all()
    data = [e.to_dict() for e in entries]
    cache.set("passwords:recent", data, ttl=CACHE_TTL)
    return jsonify(data)

if __name__ == "__main__":
    app.run(debug=True)
