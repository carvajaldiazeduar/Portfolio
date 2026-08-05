
        const units = { length: ['meters','kilometers','centimeters','millimeters','miles','yards','feet','inches'], weight: ['kilograms','grams','milligrams','pounds','ounces'], temperature: ['celsius','fahrenheit','kelvin'] };
        function populateUnits() {
            const cat = document.getElementById('category').value;
            document.getElementById('from').innerHTML = units[cat].map(u => '<option value=\"' + u + '\">' + u + '</option>').join('');
            const toSel = document.getElementById('to');
            toSel.innerHTML = units[cat].map(u => '<option value=\"' + u + '\">' + u + '</option>').join('');
            toSel.value = units[cat][1] || units[cat][0];
        }
        document.getElementById('category').addEventListener('change', populateUnits);
        populateUnits();
        document.getElementById('convertBtn').addEventListener('click', async () => {
            const value = parseFloat(document.getElementById('value').value);
            const from = document.getElementById('from').value;
            const to = document.getElementById('to').value;
            const r = await fetch('/api/convert', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({value,from,to}) });
            const data = await r.json();
            const resultDiv = document.getElementById('result');
            if (!r.ok) { resultDiv.className = 'result error'; resultDiv.textContent = data.error; }
            else { resultDiv.className = 'result success'; resultDiv.textContent = value + ' ' + from + ' = ' + data.result + ' ' + to; }
        });
    
