<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chronometer</title>
        <link rel='stylesheet' href='{{ asset('css/chronometer.css') }}'>
</head>
<body>
    <div class="card">
        <h1>Chronometer</h1>
        <div class="time" id="display">00:00.00</div>
        <div class="btns">
            <button id="startBtn">Start</button>
            <button id="stopBtn">Stop</button>
            <button id="lapBtn">Lap</button>
            <button id="resetBtn">Reset</button>
        </div>
        <div class="laps">
            <h3>Laps</h3>
            <ul id="lapsList"></ul>
        </div>
    </div>
        <script src='{{ asset('js/chronometer.js') }}'></script>
</body>
</html>


