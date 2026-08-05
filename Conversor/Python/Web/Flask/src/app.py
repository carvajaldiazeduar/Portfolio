import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'Cli'))
from flask import Flask, request, jsonify, render_template
from conversor import convert, list_categories, CATEGORY_UNITS

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html", categories=list_categories(), units=CATEGORY_UNITS)

@app.route("/api/categories")
def api_categories():
    return jsonify({cat: CATEGORY_UNITS[cat] for cat in list_categories()})

@app.route("/api/convert", methods=["POST"])
def api_convert():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Invalid JSON"}), 400
    value = data.get("value")
    from_unit = data.get("from")
    to_unit = data.get("to")
    if value is None or not from_unit or not to_unit:
        return jsonify({"error": "Missing fields: value, from, to"}), 400
    try:
        result = convert(float(value), from_unit, to_unit)
        return jsonify({"result": result, "from": from_unit, "to": to_unit, "value": float(value)})
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

if __name__ == "__main__":
    app.run(debug=True)
