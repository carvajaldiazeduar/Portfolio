from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, RedirectResponse
from pydantic import BaseModel
from models import SessionLocal, Contact
from cache import create_cache
import os

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))


@app.get("/swagger", include_in_schema=False)
async def swagger():
    return RedirectResponse("/docs")

class ContactCreate(BaseModel):
    name: str
    phone: str = ""
    email: str = ""

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

@app.get("/api/contacts")
def list_contacts():
    cached = cache.get("contacts:all")
    if cached is not None:
        return cached
    db = get_db()
    contacts = db.query(Contact).order_by(Contact.id).all()
    data = [c.to_dict() for c in contacts]
    cache.set("contacts:all", data, ttl=CACHE_TTL)
    return data

@app.post("/api/contacts", status_code=201)
def add_contact(body: ContactCreate):
    if not body.name:
        raise HTTPException(400, "Name is required")
    db = get_db()
    contact = Contact(name=body.name, phone=body.phone, email=body.email)
    db.add(contact)
    db.commit()
    cache.delete("contacts:all")
    return contact.to_dict()

@app.get("/api/contacts/search")
def search_contacts(q: str = ""):
    cached = cache.get(f"contacts:search:{q.lower()}")
    if cached is not None:
        return cached
    db = get_db()
    results = db.query(Contact).filter(Contact.name.ilike(f"%{q}%")).all()
    data = [c.to_dict() for c in results]
    cache.set(f"contacts:search:{q.lower()}", data, ttl=CACHE_TTL)
    return data

@app.delete("/api/contacts/{index}")
def delete_contact(index: int):
    db = get_db()
    contact = db.query(Contact).get(index)
    if contact is None:
        raise HTTPException(404, "Not found")
    db.delete(contact)
    db.commit()
    cache.delete("contacts:all")
    return contact.to_dict()
