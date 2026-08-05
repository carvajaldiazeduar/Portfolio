
const units = {
  length: ['meter','kilometer','centimeter','millimeter','mile','yard','foot','inch'],
  weight: ['kilogram','gram','milligram','pound','ounce'],
  temperature: ['celsius','fahrenheit','kelvin']
};

function populateUnits() {
  const cat = document.getElementById('category').value;
  const from = document.getElementById('from');
  const to = document.getElementById('to');
  const options = units[cat].map(u => `<option value="${u}">${u}</option>`).join('');
  from.innerHTML = options;
  to.innerHTML = options;
  to.value = units[cat][1] || units[cat][0];
}

document.getElementById('category').addEventListener('change', populateUnits);
populateUnits();

document.getElementById('convertBtn').addEventListener('click', async () => {
  const value = parseFloat(document.getElementById('value').value);
  const from = document.getElementById('from').value;
  const to = document.getElementById('to').value;
  const display = document.getElementById('resultDisplay');
  try {
    const res = await fetch('/api/convert', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ value, from_unit: from, to_unit: to })
    });
    const data = await res.json();
    if (data.error) {
      display.className = 'result error';
      display.textContent = data.error;
    } else {
      display.className = 'result success';
      display.textContent = `${value} ${from} = ${data.result} ${data.unit}`;
    }
  } catch (err) {
    display.className = 'result error';
    display.textContent = 'Network error';
  }
});

