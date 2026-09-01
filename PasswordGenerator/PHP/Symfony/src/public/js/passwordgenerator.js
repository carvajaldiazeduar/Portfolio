
        document.getElementById('generateBtn').addEventListener('click', async () => {
            const length = parseInt(document.getElementById('length').value) || 12;
            const r = await fetch('/api/generate', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({ length, use_upper: document.getElementById('useUpper').checked, use_lower: document.getElementById('useLower').checked, use_digits: document.getElementById('useDigits').checked, use_symbols: document.getElementById('useSymbols').checked }) });
            const data = await r.json();
            const resultDiv = document.getElementById('result');
            if (!r.ok) { resultDiv.className = 'result error'; resultDiv.textContent = data.error; }
            else { resultDiv.className = 'result success'; resultDiv.textContent = data.password; }
        });
    
