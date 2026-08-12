function showMsg(text, type) {
  const msg = document.getElementById('msg');
  msg.textContent = text;
  msg.className = 'msg ' + type;
  setTimeout(() => { msg.style.display = 'none'; }, 3000);
}

async function calculate() {
  const a = parseFloat(document.getElementById('a').value);
  const b = parseFloat(document.getElementById('b').value);
  const operator = document.getElementById('operator').value;
  const resultDiv = document.getElementById('result');

  if (isNaN(a) || isNaN(b)) {
    showMsg('Please enter both numbers', 'error');
    resultDiv.textContent = '';
    return;
  }

  try {
    const res = await fetch('/api/calculate', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({a, b, operator})
    });
    const data = await res.json();
    if (res.ok) {
      document.getElementById('msg').style.display = 'none';
      resultDiv.className = 'result';
      resultDiv.textContent = 'Result: ' + data.result;
    } else {
      resultDiv.className = 'result error';
      resultDiv.textContent = 'Error: ' + data.error;
    }
  } catch (err) {
    showMsg('Connection failed', 'error');
  }
}
