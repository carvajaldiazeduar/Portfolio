function showMsg(text, type) {
  const msg = document.getElementById('msg');
  msg.textContent = text;
  msg.className = 'msg ' + type;
  setTimeout(() => { msg.style.display = 'none'; }, 3000);
}

async function loadMessages() {
  const res = await fetch('/api/messages');
  const messages = await res.json();
  renderTable(messages);
}

async function sendMessage() {
  clearFieldState();
  const from = document.getElementById('from').value.trim();
  const subject = document.getElementById('subject').value.trim();
  const body = document.getElementById('body').value.trim();
  const res = await fetch('/api/messages', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({from, subject, body})
  });
  if (res.ok) {
    showMsg('Message sent!', 'success');
    document.getElementById('from').value = '';
    document.getElementById('subject').value = '';
    document.getElementById('body').value = '';
    loadMessages();
  } else {
    const err = await res.json();
    if (err.errors) {
      applyFieldErrors(err.errors);
      showMsg('Please fix the highlighted fields', 'error');
    } else {
      showMsg(err.error || 'Failed to send message', 'error');
    }
  }
}

function clearFieldState() {
  ['from', 'subject', 'body'].forEach((field) => {
    const input = document.getElementById(field);
    const msg = document.getElementById(field + '-msg');
    input.classList.remove('is-invalid', 'is-valid');
    msg.textContent = '';
  });
}

function applyFieldErrors(errors) {
  ['from', 'subject', 'body'].forEach((field) => {
    const input = document.getElementById(field);
    const msg = document.getElementById(field + '-msg');
    if (errors[field]) {
      input.classList.add('is-invalid');
      msg.textContent = errors[field];
      msg.className = 'field-msg error';
    } else {
      input.classList.add('is-valid');
      msg.textContent = 'Valid';
      msg.className = 'field-msg valid';
    }
  });
}

function bindClearInvalid() {
  ['from', 'subject', 'body'].forEach((field) => {
    document.getElementById(field).addEventListener('input', () => {
      const input = document.getElementById(field);
      const msg = document.getElementById(field + '-msg');
      input.classList.remove('is-invalid');
      msg.textContent = '';
    });
  });
}

async function markRead(id) {
  const res = await fetch('/api/messages/' + id);
  if (res.ok) {
    showMsg('Message marked as read', 'success');
    loadMessages();
  } else {
    showMsg('Failed to read message', 'error');
  }
}

async function deleteMessage(id) {
  if (!confirm('Delete this message?')) return;
  const res = await fetch('/api/messages/' + id, { method: 'DELETE' });
  if (res.ok) {
    showMsg('Message deleted!', 'success');
    loadMessages();
  } else {
    showMsg('Failed to delete', 'error');
  }
}

function renderTable(messages) {
  const tbody = document.getElementById('messages-body');
  tbody.innerHTML = '';
  if (messages.length === 0) {
    tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:#999;">No messages found.</td></tr>';
    return;
  }
  messages.forEach((m) => {
    const tr = document.createElement('tr');
    const status = m.read ? 'Read' : 'Unread';
    const readBtn = m.read ? '' : `<button class="delete-btn" onclick="markRead(${m.id})">Mark read</button> `;
    tr.innerHTML = `<td>${m.from || ''}</td><td>${m.subject || ''}</td><td>${status}</td>
        <td>${readBtn}<button class="delete-btn" onclick="deleteMessage(${m.id})">Delete</button></td>`;
    tbody.appendChild(tr);
  });
}

bindClearInvalid();
loadMessages();
