let currentToken = '';

async function login() {
  const username = document.getElementById('username').value;
  const password = document.getElementById('password').value;
  const res = await fetch('/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  const data = await res.json();
  if (data.token) {
    currentToken = data.token;
    document.getElementById('token').value = data.token;
    document.getElementById('token-display').classList.remove('hidden');
  } else {
    alert('Login failed: ' + (data.error || 'Unknown error'));
  }
}

function copyToken() {
  const token = document.getElementById('token');
  token.select();
  document.execCommand('copy');
  alert('Token copied to clipboard');
}

async function testEndpoint(path, authenticated = true) {
  const responseDiv = document.getElementById('response');
  responseDiv.classList.remove('hidden', 'error');
  responseDiv.textContent = 'Loading...';
  
  const headers = { 'Content-Type': 'application/json' };
  if (authenticated && currentToken) {
    headers['Authorization'] = `Bearer ${currentToken}`;
  }
  
  try {
    const res = await fetch(path, { headers });
    const data = await res.json();
    responseDiv.textContent = JSON.stringify(data, null, 2);
    if (!res.ok) responseDiv.classList.add('error');
  } catch (err) {
    responseDiv.textContent = 'Error: ' + err.message;
    responseDiv.classList.add('error');
  }
}