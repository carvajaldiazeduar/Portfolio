
        const display = document.getElementById('display');
        const lapsList = document.getElementById('lapsList');
        let timer = null;
        function formatTime(sec) {
            const m = Math.floor(sec / 60);
            const s = (sec % 60).toFixed(2);
            return String(m).padStart(2,'0') + ':' + (s < 10 ? '0' : '') + s;
        }
        async function fetchState() {
            const r = await fetch('/api/state');
            return r.json();
        }
        async function updateDisplay() {
            const state = await fetchState();
            display.textContent = formatTime(state.elapsed);
            lapsList.innerHTML = state.laps.map((l,i) => '<li>Lap ' + (i+1) + ': ' + formatTime(l) + '</li>').join('');
            if (state.running && !timer) { timer = setInterval(updateDisplay, 50); }
            else if (!state.running && timer) { clearInterval(timer); timer = null; }
        }
        async function doAction(action) {
            await fetch('/api/' + action, { method: 'POST' });
            updateDisplay();
        }
        document.getElementById('startBtn').addEventListener('click', () => doAction('start'));
        document.getElementById('stopBtn').addEventListener('click', () => doAction('stop'));
        document.getElementById('resetBtn').addEventListener('click', () => doAction('reset'));
        document.getElementById('lapBtn').addEventListener('click', () => doAction('lap'));
        updateDisplay();
    
