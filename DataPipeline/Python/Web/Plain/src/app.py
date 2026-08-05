import os
from flask import Flask, request, jsonify, render_template
from storage.warehouse_factory import create_warehouse
from cache.cache_factory import create_cache

app = Flask(__name__)
warehouse = create_warehouse()
cache = create_cache()
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/pipelines", methods=["GET"])
def list_pipelines():
    cached = cache.get("pipelines:all")
    if cached is not None:
        return jsonify(cached)
    tables = warehouse.list_tables()
    cache.set("pipelines:all", tables, ttl=CACHE_TTL)
    return jsonify({"pipelines": tables})


@app.route("/api/pipelines/<name>/run", methods=["POST"])
def run_pipeline(name):
    data = request.get_json() or {}
    source = data.get("source", "")
    query = data.get("query", f"SELECT * FROM {name}")
    try:
        results = warehouse.execute(query)
        target = data.get("target", f"processed_{name}")
        schema = data.get("schema", {})
        warehouse.create_table(target, schema)
        warehouse.bulk_insert(target, results)
        cache.delete("pipelines:all")
        return jsonify({"message": "Pipeline executed", "rows": len(results), "target": target})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/sources", methods=["GET"])
def list_sources():
    sources = [
        {"name": "rest_api", "type": "REST", "status": "active"},
        {"name": "web_scraper", "type": "Scraper", "status": "active"},
        {"name": "scheduled_feed", "type": "Scheduled", "status": "active"},
    ]
    return jsonify({"sources": sources})


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "warehouse": "connected"})


@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not found"}), 404


if __name__ == "__main__":
    app.run(debug=True)