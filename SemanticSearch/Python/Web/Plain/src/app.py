import os
from flask import Flask, request, jsonify, render_template, send_from_directory
from storage.vector_factory import create_vector_store
from cache.cache_factory import create_cache

app = Flask(__name__)
vector_store = create_vector_store()
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/upload", methods=["POST"])
def upload_document():
    file = request.files.get("file")
    if not file:
        return jsonify({"error": "No file provided"}), 400
    content = file.read().decode("utf-8", errors="replace")
    metadata = {"filename": file.filename, "source": "upload"}
    vector_store.add_documents([content], [[0.0] * int(os.getenv("VECTOR_DIMENSION", "1536"))], [metadata])
    cache.delete("search:results")
    return jsonify({"message": "Document indexed", "filename": file.filename}), 201


@app.route("/api/search", methods=["GET"])
def search():
    query = request.args.get("q", "")
    if not query:
        return jsonify({"error": "Query parameter 'q' is required"}), 400
    cached = cache.get(f"search:{query}")
    if cached is not None:
        return jsonify(cached)
    embedding = [0.0] * int(os.getenv("VECTOR_DIMENSION", "1536"))
    results = vector_store.search(embedding, n_results=5)
    payload = {"query": query, "results": results}
    cache.set(f"search:{query}", payload, ttl=CACHE_TTL)
    return jsonify(payload)


@app.route("/api/collections", methods=["GET"])
def list_collections():
    collections = vector_store.list_collections()
    return jsonify({"collections": collections})


@app.route("/api/collections/<name>", methods=["DELETE"])
def delete_collection(name):
    vector_store.delete_collection(name)
    cache.delete("search:results")
    return jsonify({"message": f"Collection '{name}' deleted"})


@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not found"}), 404


@app.route("/openapi.json")
def openapi_spec():
    return send_from_directory("static", "openapi.json")


@app.route("/swagger")
def swagger():
    return send_from_directory("static", "swagger.html")


if __name__ == "__main__":
    app.run(debug=True)