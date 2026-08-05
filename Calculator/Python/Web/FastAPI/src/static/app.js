
  document.getElementById('calcBtn').addEventListener('click', async () => {
    const a = parseFloat(document.getElementById('a').value);
    const b = parseFloat(document.getElementById('b').value);
    const operator = document.getElementById('op').value;
    const display = document.getElementById('resultDisplay');
    try {
      const res = await fetch('/api/calculate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ a, b, operator })
      });
      const data = await res.json();
      if (data.error) {
        display.className = 'result error';
        display.textContent = data.error;
      } else {
        display.className = 'result success';
        display.textContent = `Result: ${data.result}`;
      }
    } catch (err) {
      display.className = 'result error';
      display.textContent = 'Network error';
    }
  });

