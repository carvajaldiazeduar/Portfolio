function showMsg(text, type) {
  const msg = document.getElementById('msg');
  msg.textContent = text;
  msg.className = 'msg ' + type;
  setTimeout(() => { msg.style.display = 'none'; }, 3000);
}

let currentPassword = '';

async function generatePassword() {
  const length = parseInt(document.getElementById('length').value) || 16;
  const params = new URLSearchParams({
    length: length,
    uppercase: document.getElementById('uppercase').checked,
    lowercase: document.getElementById('lowercase').checked,
    numbers: document.getElementById('numbers').checked,
    symbols: document.getElementById('symbols').checked
  });
  const res = await fetch('/api/generate?' + params.toString());
  const data = await res.json();
  const result = document.getElementById('result');
  if (res.ok) {
    currentPassword = data.password;
    result.textContent = 'Password: ' + data.password;
    result.className = 'result';
    showMsg('Password generated!', 'success');
  } else {
    currentPassword = '';
    result.textContent = 'Error: ' + (data.errors ? Object.values(data.errors)[0] : 'Generation failed');
    result.className = 'result error';
    showMsg('Could not generate password', 'error');
  }
}

async function storePassword() {
  if (!currentPassword) {
    showMsg('Generate a password first', 'error');
    return;
  }
  const res = await fetch('/api/passwords', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({password: currentPassword})
  });
  if (res.ok) {
    showMsg('Password stored!', 'success');
    loadPasswords();
  } else {
    const err = await res.json();
    showMsg(err.errors ? Object.values(err.errors)[0] : 'Failed to store', 'error');
  }
}

async function loadPasswords() {
  const res = await fetch('/api/passwords');
  const passwords = await res.json();
  renderTable(passwords);
}

async function deletePassword(id) {
  if (!confirm('Delete this stored password?')) return;
  const res = await fetch('/api/passwords/' + id, { method: 'DELETE' });
  if (res.ok) {
    showMsg('Password deleted!', 'success');
    loadPasswords();
  } else {
    showMsg('Failed to delete', 'error');
  }
}

function renderTable(passwords) {
  const tbody = document.getElementById('passwords-body');
  tbody.innerHTML = '';
  if (passwords.length === 0) {
    tbody.innerHTML = '<tr><td colspan="2" style="text-align:center;color:#999;">No stored passwords.</td></tr>';
    return;
  }
  passwords.forEach((p) => {
    const tr = document.createElement('tr');
    tr.innerHTML = `<td>${p.password}</td>
        <td><button class="delete-btn" onclick="deletePassword(${p.id})">Delete</button></td>`;
    tbody.appendChild(tr);
  });
}

loadPasswords();
