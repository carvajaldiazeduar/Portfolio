
        document.getElementById('generateBtn').addEventListener('click', async () => {
            const length = parseInt(document.getElementById('length').value) || 12;
            const useUpper = document.getElementById('useUpper').checked;
            const useLower = document.getElementById('useLower').checked;
            const useDigits = document.getElementById('useDigits').checked;
            const useSymbols = document.getElementById('useSymbols').checked;
            const resultDiv = document.getElementById('result');

            try {
                const r = await fetch('/api/generate', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ length, use_upper: useUpper, use_lower: useLower, use_digits: useDigits, use_symbols: useSymbols })
                });
                const data = await r.json();
                if (!r.ok) {
                    resultDiv.className = 'result error';
                    resultDiv.textContent = data.error;
                } else {
                    resultDiv.className = 'result success';
                    resultDiv.textContent = data.password;
                }
            } catch {
                resultDiv.className = 'result error';
                resultDiv.textContent = 'Network error';
            }
        });
    
