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

function setState(state) {
  const status = document.getElementById('status');
  status.textContent = state === 'running' ? 'Running' : 'Stopped';
  status.className = 'status ' + (state === 'running' ? 'running' : 'stopped');
}

async function refresh() {
  try {
    const res = await fetch('/status');
    const data = await res.json();
    if (res.ok) {
      document.getElementById('display').textContent = formatTime(data.elapsed);
      setState(data.state);
    }
  } catch (err) {
    showMsg('Connection failed', 'error');
  }
}

async function apiCall(endpoint, successMsg) {
  try {
    const res = await fetch(endpoint, {method: 'POST'});
    const data = await res.json();
    if (res.ok) {
      document.getElementById('display').textContent = formatTime(data.elapsed || 0);
      setState(data.state || 'stopped');
      if (successMsg) showMsg(successMsg, 'success');
    } else {
      showMsg(data.error || 'Request failed', 'error');
    }
  } catch (err) {
    showMsg('Connection failed', 'error');
  }
}

document.getElementById('startBtn').addEventListener('click', function () { apiCall('/start', 'Started'); });
document.getElementById('pauseBtn').addEventListener('click', function () { apiCall('/pause', 'Paused'); });
document.getElementById('resumeBtn').addEventListener('click', function () { apiCall('/resume', 'Resumed'); });
document.getElementById('resetBtn').addEventListener('click', function () { apiCall('/reset', 'Reset'); });

setInterval(refresh, 200);
refresh();
