async function loadQueues() {
  try {
    const res = await fetch('/api/queues');
    const data = await res.json();
    const container = document.getElementById('queue-list');
    container.innerHTML = data.queues.map(q => `<span class="queue-item">${q}</span>`).join('');
  } catch (err) {
    console.error('Failed to load queues:', err);
  }
}

async function submitJob() {
  const type = document.getElementById('job-type').value;
  let data;
  try {
    data = JSON.parse(document.getElementById('job-data').value);
  } catch {
    alert('Invalid JSON in job data');
    return;
  }
  
  const responseDiv = document.getElementById('response');
  responseDiv.classList.remove('hidden', 'error');
  responseDiv.textContent = 'Submitting...';
  
  try {
    const res = await fetch('/api/jobs', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type, data }),
    });
    const result = await res.json();
    responseDiv.textContent = JSON.stringify(result, null, 2);
    if (!res.ok) responseDiv.classList.add('error');
  } catch (err) {
    responseDiv.textContent = 'Error: ' + err.message;
    responseDiv.classList.add('error');
  }
}

async function submitBatch() {
  const jobs = [
    { type: 'image.process', data: { imageUrl: 'https://example.com/img1.jpg', operations: ['resize'] } },
    { type: 'email.bulk', data: { recipients: ['a@test.com', 'b@test.com'], subject: 'Test', template: 'welcome' } },
    { type: 'report.generate', data: { reportType: 'monthly', data: { month: '2024-01' } } },
  ];
  
  const responseDiv = document.getElementById('response');
  responseDiv.classList.remove('hidden', 'error');
  responseDiv.textContent = 'Submitting batch...';
  
  try {
    const res = await fetch('/api/jobs/batch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ jobs }),
    });
    const result = await res.json();
    responseDiv.textContent = JSON.stringify(result, null, 2);
    if (!res.ok) responseDiv.classList.add('error');
  } catch (err) {
    responseDiv.textContent = 'Error: ' + err.message;
    responseDiv.classList.add('error');
  }
}

loadQueues();