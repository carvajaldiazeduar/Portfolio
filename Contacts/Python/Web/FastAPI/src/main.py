import re
from fastapi import FastAPI, HTTPException, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, RedirectResponse
from pydantic import BaseModel, field_validator
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

NAME_RE = re.compile(r"^[A-Za-zÀ-ÿ' .-]+$")
PHONE_RE = re.compile(r"^[0-9 +().-]{7,20}$")
EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$")

NAME_REQUIRED = "Name is required"
PHONE_REQUIRED = "Phone is required"
EMAIL_REQUIRED = "Email is required"
NAME_FORMAT = "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)"
PHONE_FORMAT = "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)"
EMAIL_FORMAT = "Invalid email format"

class ContactCreate(BaseModel):
    name: str
    phone: str
    email: str

    @field_validator("name")
    @classmethod
    def validate_name(cls, v):
        v = v.strip()
        if not v:
            raise ValueError(NAME_REQUIRED)
        if not (2 <= len(v) <= 100) or not NAME_RE.match(v):
            raise ValueError(NAME_FORMAT)
        return v

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v):
        v = v.strip()
        if not v:
            raise ValueError(PHONE_REQUIRED)
        if not PHONE_RE.match(v):
            raise ValueError(PHONE_FORMAT)
        return v

    @field_validator("email")
    @classmethod
    def validate_email(cls, v):
        v = v.strip()
        if not v:
            raise ValueError(EMAIL_REQUIRED)
        if not EMAIL_RE.match(v):
            raise ValueError(EMAIL_FORMAT)
        return v

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = {}
    for err in exc.errors():
        loc = err.get("loc", ()) or ()
        field = loc[-1] if loc else ""
        if field not in ("name", "phone", "email"):
            continue
        if err.get("type") == "missing":
            errors[field] = {"name": NAME_REQUIRED, "phone": PHONE_REQUIRED, "email": EMAIL_REQUIRED}[field]
        elif err.get("type") == "value_error":
            ctx = err.get("ctx") or {}
            error = ctx.get("error")
            errors[field] = str(error) if error else err.get("msg", "Invalid value")
        else:
            errors[field] = err.get("msg", "Invalid value")
    if not errors:
        return JSONResponse(status_code=422, content={"detail": jsonable_encoder(exc.errors())})
    return JSONResponse(status_code=400, content={"errors": errors})

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
