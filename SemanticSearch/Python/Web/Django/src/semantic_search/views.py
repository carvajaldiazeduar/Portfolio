import os
from django.http import FileResponse, JsonResponse, HttpResponse
from django.shortcuts import render
from storage.vector_factory import create_vector_store
from cache.cache_factory import create_cache

vector_store = create_vector_store()
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))


def index(request):
    return render(request, "index.html")


def openapi_spec(request):
    path = os.path.join(os.path.dirname(__file__), "static", "openapi.json")
    return FileResponse(open(path, "rb"), content_type="application/json")


def swagger(request):
    path = os.path.join(os.path.dirname(__file__), "static", "swagger.html")
    return FileResponse(open(path, "rb"), content_type="text/html")


def search(request):
    q = request.GET.get("q", "")
    if not q:
        return JsonResponse({"error": "Query parameter 'q' is required"}, status=400)
    cached = cache.get(f"search:{q}")
    if cached is not None:
        return JsonResponse({"query": q, "results": cached})
    embedding = [0.0] * int(os.getenv("VECTOR_DIMENSION", "1536"))
    results = vector_store.search(embedding, n_results=5)
    cache.set(f"search:{q}", results, ttl=CACHE_TTL)
    return JsonResponse({"query": q, "results": results})


def upload_document(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    file = request.FILES.get("file")
    if not file:
        return JsonResponse({"error": "No file provided"}, status=400)
    content = file.read().decode("utf-8", errors="replace")
    metadata = {"filename": file.name, "source": "upload"}
    vector_store.add_documents([content], [[0.0] * int(os.getenv("VECTOR_DIMENSION", "1536"))], [metadata])
    cache.delete("search:results")
    return JsonResponse({"message": "Document indexed", "filename": file.name})


def list_collections(request):
    collections = vector_store.list_collections()
    return JsonResponse({"collections": collections})