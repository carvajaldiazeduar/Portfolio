<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Conversor</title>
        <link rel='stylesheet' href='{{ asset('css/conversor.css') }}'>
</head>
<body>
    <div class="card">
        <h1>Conversor</h1>
        <div class="form-group">
            <label for="category">Category</label>
            <select id="category">
                <option value="length">Length</option>
                <option value="weight">Weight</option>
                <option value="temperature">Temperature</option>
            </select>
        </div>
        <div class="form-group">
            <label for="value">Value</label>
            <input type="number" id="value" step="any" value="1">
        </div>
        <div class="form-group">
            <label for="from">From</label>
            <select id="from"></select>
        </div>
        <div class="form-group">
            <label for="to">To</label>
            <select id="to"></select>
        </div>
        <button id="convertBtn">Convert</button>
        <div id="result" class="result"></div>
    </div>
        <script src='{{ asset('js/conversor.js') }}'></script>
</body>
</html>


