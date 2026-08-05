
        document.getElementById('calculateBtn').addEventListener('click', async function () {
            const a = document.getElementById('a').value;
            const b = document.getElementById('b').value;
            const operator = document.getElementById('operator').value;
            const resultDiv = document.getElementById('result');

            if (a === '' || b === '') {
                resultDiv.className = 'result error';
                resultDiv.textContent = 'Please fill in both numbers';
                return;
            }

            try {
                const response = await fetch('/calculate', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                    body: JSON.stringify({ a: parseFloat(a), b: parseFloat(b), operator })
                });

                const data = await response.json();

                if (!response.ok) {
                    resultDiv.className = 'result error';
                    resultDiv.textContent = data.error || 'An error occurred';
                } else {
                    resultDiv.className = 'result success';
                    resultDiv.textContent = 'Result: ' + data.result;
                }
            } catch (err) {
                resultDiv.className = 'result error';
                resultDiv.textContent = 'Network error';
            }
        });
    
