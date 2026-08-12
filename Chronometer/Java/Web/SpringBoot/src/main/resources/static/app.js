function showMsg(text, type) {
  const msg = document.getElementById('msg');
  msg.textContent = text;
  msg.className = 'msg ' + type;
  setTimeout(() => { msg.style.display = 'none'; }, 2000);
}

function formatTime(seconds) {
  const totalMs = Math.round((seconds || 0) * 1000);
  const hours = Math.floor(totalMs / 3600000);
  const minutes = Math.floor((totalMs % 3600000) / 60000);
  const secs = Math.floor((totalMs % 60000) / 1000);
  const millis = totalMs % 1000;
  return String(hours).padStart(2, '0') + ':' + String(minutes).padStart(2, '0') + ':' + String(secs).padStart(2, '0') + '.' + String(millis).padStart(3, '0');
}

function setRunning(running) {
  document.getElementById('status').textContent = running ? 'Running' : 'Stopped';
}

async function refresh() {
  try {
    const res = await fetch('/api/state');
    const data = await res.json();
    document.getElementById('display').textContent = data.time_str || formatTime(data.time);
    setRunning(data.running);
    renderLaps(data.laps || []);
  } catch (err) {
    showMsg('Connection failed', 'error');
  }
}

function renderLaps(laps) {
  const list = document.getElementById('lapList');
  if (!list) return;
  list.innerHTML = laps.map(function (lap, i) {
    return '<li>Lap ' + (i + 1) + ': ' + lap.cumulative_str + ' (split ' + lap.split_str + ')</li>';
  }).join('');
}

async function apiCall(endpoint, successMsg) {
  try {
    const res = await fetch(endpoint, {method: 'POST'});
    const data = await res.json();
    if (res.ok) {
      document.getElementById('display').textContent = data.time_str || formatTime(data.time);
      setRunning(data.running);
      renderLaps(data.laps || []);
      if (successMsg) showMsg(successMsg, 'success');
    } else {
      showMsg(data.error || 'Request failed', 'error');
    }
  } catch (err) {
    showMsg('Connection failed', 'error');
  }
}

function start() { apiCall('/api/start', 'Started'); }
function stop() { apiCall('/api/stop', 'Stopped'); }
function reset() { apiCall('/api/reset', 'Reset'); }
function lap() { apiCall('/api/lap', 'Lap recorded'); }

document.getElementById('startBtn').addEventListener('click', start);
document.getElementById('stopBtn').addEventListener('click', stop);
document.getElementById('resetBtn').addEventListener('click', reset);
document.getElementById('lapBtn').addEventListener('click', lap);

setInterval(refresh, 200);
refresh();
