import os
from fastapi import FastAPI, UploadFile, File, Query
from fastapi.responses import HTMLResponse
from storage.vector_factory import create_vector_store
from cache.cache_factory import create_cache

app = FastAPI()
vector_store = create_vector_store()
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))


@app.get("/")
def index():
    return HTMLResponse("<h1>Semantic Search</h1><form action='/upload' method='post' enctype='multipart/form-data'><input type='file' name='file'><button type='submit'>Upload</button></form><br><form action='/search'><input name='q'><button type='submit'>Search</button></form>")


@app.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    content = await file.read()
    text = content.decode("utf-8", errors="replace")
    metadata = {"filename": file.filename, "source": "upload"}
    vector_store.add_documents([text], [[0.0] * int(os.getenv("VECTOR_DIMENSION", "1536"))], [metadata])
    cache.delete("search:results")
    return {"message": "Document indexed", "filename": file.filename}


@app.get("/search")
def search(q: str = Query(...)):
    cached = cache.get(f"search:{q}")
    if cached is not None:
        return {"query": q, "results": cached}
    embedding = [0.0] * int(os.getenv("VECTOR_DIMENSION", "1536"))
    results = vector_store.search(embedding, n_results=5)
    cache.set(f"search:{q}", results, ttl=CACHE_TTL)
    return {"query": q, "results": results}


@app.get("/collections")
def list_collections():
    return {"collections": vector_store.list_collections()}


@app.delete("/collections/{name}")
def delete_collection(name: str):
    vector_store.delete_collection(name)
    cache.delete("search:results")
    return {"message": f"Collection '{name}' deleted"}