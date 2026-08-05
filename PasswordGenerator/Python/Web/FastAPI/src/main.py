import random
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from models import SessionLocal, PasswordEntry
from cache import create_cache
import os

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))

UPPERCASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
LOWERCASE = "abcdefghijklmnopqrstuvwxyz"
DIGITS = "0123456789"
SYMBOLS = "!@#$%^&*()_+-=[]{}|;:,.<>?"

class GenerateRequest(BaseModel):
    length: int = 16
    use_upper: bool = True
    use_lower: bool = True
    use_digits: bool = True
    use_symbols: bool = True

def get_db():
    db = SessionLocal()
    try:
        return db
    finally:
        db.close()

def generate_password(length=16, use_upper=True, use_lower=True, use_digits=True, use_symbols=True):
    if length < 1:
        raise ValueError("Password length must be at least 1")
    categories = []
    if use_upper: categories.append(UPPERCASE)
    if use_lower: categories.append(LOWERCASE)
    if use_digits: categories.append(DIGITS)
    if use_symbols: categories.append(SYMBOLS)
    if not categories:
        raise ValueError("At least one character category must be enabled")
    if length < len(categories):
        raise ValueError(f"Password length must be at least {len(categories)}")
    password = [random.choice(cat) for cat in categories]
    all_chars = "".join(categories)
    password.extend(random.choice(all_chars) for _ in range(length - len(categories)))
    random.shuffle(password)
    return "".join(password)

@app.get("/", response_class=HTMLResponse)
def index():
    with open("static/index.html") as f:
        return f.read()

@app.post("/api/generate")
def api_generate(body: GenerateRequest):
    try:
        password = generate_password(body.length, body.use_upper, body.use_lower, body.use_digits, body.use_symbols)
        db = get_db()
        entry = PasswordEntry(password=password, length=body.length)
        db.add(entry)
        db.commit()
        cache.delete("passwords:recent")
        return {"password": password, "id": entry.id}
    except ValueError as e:
        raise HTTPException(400, str(e))

@app.get("/api/passwords")
def list_passwords():
    cached = cache.get("passwords:recent")
    if cached is not None:
        return cached
    db = get_db()
    entries = db.query(PasswordEntry).order_by(PasswordEntry.id.desc()).limit(50).all()
    data = [e.to_dict() for e in entries]
    cache.set("passwords:recent", data, ttl=CACHE_TTL)
    return data
