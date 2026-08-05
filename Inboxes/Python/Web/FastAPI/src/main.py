from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from models import SessionLocal, Message
from cache import create_cache
import os

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))

class MessageCreate(BaseModel):
    sender: str
    subject: str
    body: str = ""

def get_db():
    db = SessionLocal()
    try:
        return db
    finally:
        db.close()

@app.get("/", response_class=HTMLResponse)
def index():
    with open("static/index.html") as f:
        return f.read()

@app.get("/api/messages")
def list_messages():
    cached = cache.get("messages:all")
    if cached is not None:
        return cached
    db = get_db()
    msgs = db.query(Message).order_by(Message.id).all()
    data = [m.to_dict() for m in msgs]
    cache.set("messages:all", data, ttl=CACHE_TTL)
    return data

@app.post("/api/messages", status_code=201)
def send_message(body: MessageCreate):
    if not body.sender or not body.subject:
        raise HTTPException(400, "sender and subject are required")
    db = get_db()
    msg = Message(sender=body.sender, subject=body.subject, body=body.body)
    db.add(msg)
    db.commit()
    cache.delete("messages:all")
    return msg.to_dict()

@app.get("/api/messages/{id}")
def read_message(id: int):
    cached = cache.get(f"message:{id}")
    if cached is not None:
        return cached
    db = get_db()
    msg = db.query(Message).get(id)
    if msg is None:
        raise HTTPException(404, "not found")
    msg.read = True
    db.commit()
    data = msg.to_dict()
    cache.set(f"message:{id}", data, ttl=CACHE_TTL)
    cache.delete("messages:all")
    return data

@app.delete("/api/messages/{id}", status_code=204)
def delete_message(id: int):
    db = get_db()
    msg = db.query(Message).get(id)
    if msg is None:
        raise HTTPException(404, "not found")
    db.delete(msg)
    db.commit()
    cache.delete("messages:all")
    cache.delete(f"message:{id}")
