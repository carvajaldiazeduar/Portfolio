document.addEventListener('DOMContentLoaded', () => {
  loadPipelineStatus();
  loadFiles();
  loadMetrics();

  const form = document.getElementById('upload-form');
  if (form) {
    form.addEventListener('submit', handleUpload);
  }

  const refreshFiles = document.getElementById('refresh-files');
  if (refreshFiles) {
    refreshFiles.addEventListener('click', loadFiles);
  }

  const refreshMetrics = document.getElementById('refresh-metrics');
  if (refreshMetrics) {
    refreshMetrics.addEventListener('click', loadMetrics);
  }
});

async function loadPipelineStatus() {
  try {
    const res = await fetch('/api/pipeline/status');
    const data = await res.json();
    const container = document.getElementById('pipeline-status');
    if (container) {
      container.innerHTML = `
        <p><strong>Service:</strong> ${data.service}</p>
        <p><strong>AWS Endpoint:</strong> ${data.awsEndpoint}</p>
        <p><strong>Region:</strong> ${data.region}</p>
        <p><strong>DB Driver:</strong> ${data.dbDriver}</p>
        <p><strong>Uptime:</strong> ${Math.floor(data.uptime)}s</p>
      `;
    }
  } catch (err) {
    console.error('Failed to load pipeline status:', err);
  }
}

async function handleUpload(e) {
  e.preventDefault();
  const form = e.target;
  const formData = new FormData(form);
  const responseDiv = document.getElementById('upload-response');
  responseDiv.classList.remove('hidden', 'error');
  responseDiv.textContent = 'Uploading...';

  try {
    const res = await fetch('/api/pipeline/upload', {
      method: 'POST',
      body: formData,
    });
    const result = await res.json();
    responseDiv.innerHTML = `<pre>${JSON.stringify(result, null, 2)}</pre>`;
    if (!res.ok) responseDiv.classList.add('error');
    loadFiles();
  } catch (err) {
    responseDiv.textContent = 'Error: ' + err.message;
    responseDiv.classList.add('error');
  }
}

async function loadFiles() {
  try {
    const res = await fetch('/api/pipeline/files');
    const data = await res.json();
    const container = document.getElementById('files-list');
    if (container) {
      if (data.count === 0) {
        container.innerHTML = '<p>No files processed yet.</p>';
      } else {
        container.innerHTML = data.files.map(f => `
          <div class="file-item">
            <strong>${f.fileName || f.id}</strong>
            <span class="badge">${f.status || 'unknown'}</span>
          </div>
        `).join('');
      }
    }
  } catch (err) {
    console.error('Failed to load files:', err);
  }
}

async function loadMetrics() {
  try {
    const res = await fetch('/api/pipeline/metrics');
    const data = await res.json();
    const container = document.getElementById('metrics-list');
    if (container) {
      if (data.count === 0) {
        container.innerHTML = '<p>No metrics recorded yet.</p>';
      } else {
        container.innerHTML = data.metrics.map(m => `
          <div class="metric-item">
            <strong>${m.key}</strong>
            <span>${m.processingTime || 0}ms</span>
          </div>
        `).join('');
      }
    }
  } catch (err) {
    console.error('Failed to load metrics:', err);
  }
}
