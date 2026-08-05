
async function loadMessages() {
  const res = await fetch('/api/messages');
  const msgs = await res.json();
  const tbody = document.getElementById('messages-body');
  tbody.innerHTML = '';
  msgs.forEach(m => {
    const tr = document.createElement('tr');
    tr.className = m.read ? 'read' : 'unread';
    tr.innerHTML = `<td>${m.id}</td><td>${m.from}</td><td>${m.subject}</td>
      <td>${m.read ? '✓ read' : '✗ unread'}</td><td>${m.created_at}</td>
      <td>
        <button onclick="viewMessage(${m.id})">Read</button>
        <button onclick="deleteMessage(${m.id})">Delete</button>
      </td>`;
    tbody.appendChild(tr);
  });
}

async function viewMessage(id) {
  const res = await fetch(`/api/messages/${id}`);
  const m = await res.json();
  document.getElementById('detail-from').textContent = m.from;
  document.getElementById('detail-subject').textContent = m.subject;
  document.getElementById('detail-date').textContent = m.created_at;
  document.getElementById('detail-body').textContent = m.body;
  document.getElementById('message-detail').style.display = 'block';
  loadMessages();
}

async function deleteMessage(id) {
  await fetch(`/api/messages/${id}`, { method: 'DELETE' });
  loadMessages();
}

document.getElementById('send-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  await fetch('/api/messages', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from: document.getElementById('from').value,
      subject: document.getElementById('subject').value,
      body: document.getElementById('body').value,
    })
  });
  e.target.reset();
  loadMessages();
});

loadMessages();

