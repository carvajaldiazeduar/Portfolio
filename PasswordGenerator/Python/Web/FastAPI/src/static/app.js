
document.getElementById('generateBtn').addEventListener('click', async () => {
  const length = parseInt(document.getElementById('length').value) || 12;
  const use_upper = document.getElementById('useUpper').checked;
  const use_lower = document.getElementById('useLower').checked;
  const use_digits = document.getElementById('useDigits').checked;
  const use_symbols = document.getElementById('useSymbols').checked;
  const display = document.getElementById('resultDisplay');
  try {
    const res = await fetch('/api/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ length, use_upper, use_lower, use_digits, use_symbols })
    });
    const data = await res.json();
    if (data.error) {
      display.className = 'result error';
      display.textContent = data.error;
    } else {
      display.className = 'result show';
      display.textContent = data.password;
    }
  } catch (err) {
    display.className = 'result error';
    display.textContent = 'Network error';
  }
});

