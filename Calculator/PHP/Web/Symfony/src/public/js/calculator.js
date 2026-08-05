
        document.getElementById('calculate').addEventListener('click', async () => {
            const a = parseFloat(document.getElementById('a').value);
            const b = parseFloat(document.getElementById('b').value);
            const operator = document.getElementById('operator').value;
            const resultEl = document.getElementById('result');

            try {
                const res = await fetch('/api/calculate', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ a, b, operator })
                });
                const data = await res.json();
                if (!res.ok) {
                    resultEl.className = 'result-box error';
                    resultEl.textContent = data.error;
                } else {
                    resultEl.className = 'result-box success';
                    resultEl.textContent = 'Result: ' + data.result;
                }
                resultEl.style.display = 'block';
            } catch {
                resultEl.className = 'result-box error';
                resultEl.textContent = 'Network error';
                resultEl.style.display = 'block';
            }
        });
    
