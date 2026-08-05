from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from models import SessionLocal, Task
from cache import create_cache
import os

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))

class TaskCreate(BaseModel):
    title: str
    description: str = ""

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

@app.get("/api/tasks")
def get_tasks():
    cached = cache.get("tasks:all")
    if cached is not None:
        return cached
    db = get_db()
    tasks = db.query(Task).order_by(Task.id).all()
    data = [t.to_dict() for t in tasks]
    cache.set("tasks:all", data, ttl=CACHE_TTL)
    return data

@app.post("/api/tasks", status_code=201)
def add_task(body: TaskCreate):
    if not body.title.strip():
        raise HTTPException(400, "Title is required")
    db = get_db()
    task = Task(title=body.title.strip(), description=body.description.strip())
    db.add(task)
    db.commit()
    cache.delete("tasks:all")
    return task.to_dict()

@app.put("/api/tasks/{task_id}/complete")
def complete_task(task_id: int):
    db = get_db()
    task = db.query(Task).get(task_id)
    if task is None:
        raise HTTPException(404, "Task not found")
    task.completed = True
    db.commit()
    cache.delete("tasks:all")
    return task.to_dict()

@app.delete("/api/tasks/{task_id}")
def delete_task(task_id: int):
    db = get_db()
    task = db.query(Task).get(task_id)
    if task is None:
        raise HTTPException(404, "Task not found")
    db.delete(task)
    db.commit()
    cache.delete("tasks:all")
    return {"result": "deleted"}
