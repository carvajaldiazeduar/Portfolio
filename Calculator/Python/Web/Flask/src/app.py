import math
from flask import Flask, render_template, request, jsonify, send_from_directory

app = Flask(__name__)

ALLOWED_OPERATORS = {"add", "subtract", "multiply", "divide"}
MAX_INPUT_SIZE = 1000


@app.after_request
def add_security_headers(response):
    response.headers["Content-Security-Policy"] = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline'; "
        "style-src 'self' 'unsafe-inline'"
    )
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    return response


def is_safe_number(value):
    if not math.isfinite(value):
        return False
    return True


def calculate(a, b, operator):
    if operator == "add":
        return a + b
    elif operator == "subtract":
        return a - b
    elif operator == "multiply":
        return a * b
    elif operator == "divide":
        if b == 0:
            return None
        return a / b
    return None


@app.route("/")
def index():
    return render_template("calculator.html")


@app.route("/calculate", methods=["POST"])
def calculate_route():
    if request.content_length and request.content_length > MAX_INPUT_SIZE:
        return jsonify({"error": "Request too large"}), 413

    data = request.get_json(silent=True)
    if data is None:
        return jsonify({"error": "Invalid JSON"}), 400

    operator = data.get("operator")
    if operator not in ALLOWED_OPERATORS:
        return jsonify({"error": "Invalid operator"}), 400

    try:
        a = float(data["a"])
        b = float(data["b"])
    except (TypeError, ValueError, KeyError):
        return jsonify({"error": "Invalid number input"}), 400

    if not is_safe_number(a) or not is_safe_number(b):
        return jsonify({"error": "Invalid number input"}), 400

    result = calculate(a, b, operator)

    if result is None:
        return jsonify({"error": "Cannot divide by zero"}), 400

    if not is_safe_number(result):
        return jsonify({"error": "Calculation overflow"}), 400

    return jsonify({"result": result})


@app.route("/openapi.json")
def openapi_spec():
    return send_from_directory("static", "openapi.json")


@app.route("/swagger")
def swagger():
    return send_from_directory("static", "swagger.html")


if __name__ == "__main__":
    app.run(debug=True)
