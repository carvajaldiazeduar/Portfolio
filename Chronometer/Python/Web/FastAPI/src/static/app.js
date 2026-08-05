
function formatTime(seconds) {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  const ds = Math.floor((seconds % 1) * 10);
  return `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}.${ds}`;
}

async function updateState() {
  const res = await fetch('/api/state');
  const data = await res.json();
  document.getElementById('display').textContent = formatTime(data.elapsed);
  const lapList = document.getElementById('lapList');
  lapList.innerHTML = data.laps.map((l, i) => `<li>Lap ${i+1}: ${formatTime(l)}</li>`).join('');
}

async function apiCall(endpoint) {
  await fetch(endpoint, { method: 'POST' });
  await updateState();
}

document.getElementById('startBtn').addEventListener('click', () => apiCall('/api/start'));
document.getElementById('stopBtn').addEventListener('click', () => apiCall('/api/stop'));
document.getElementById('resetBtn').addEventListener('click', () => apiCall('/api/reset'));
document.getElementById('lapBtn').addEventListener('click', () => apiCall('/api/lap'));

updateState();
setInterval(updateState, 100);

