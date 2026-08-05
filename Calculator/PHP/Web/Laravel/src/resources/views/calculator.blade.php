<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Calculator</title>
        <link rel='stylesheet' href='{{ asset('css/calculator.css') }}'>
</head>
<body>
    <div class="container">
        <h1>Calculator</h1>
        <div class="form-group">
            <label for="a">Number A</label>
            <input type="number" id="a" step="any" placeholder="Enter first number">
        </div>
        <div class="form-group">
            <label for="b">Number B</label>
            <input type="number" id="b" step="any" placeholder="Enter second number">
        </div>
        <div class="form-group">
            <label for="operator">Operator</label>
            <select id="operator">
                <option value="add">Add (+)</option>
                <option value="subtract">Subtract (−)</option>
                <option value="multiply">Multiply (×)</option>
                <option value="divide">Divide (÷)</option>
            </select>
        </div>
        <button id="calculateBtn">Calculate</button>
        <div id="result" class="result"></div>
    </div>

        <script src='{{ asset('js/calculator.js') }}'></script>
</body>
</html>


