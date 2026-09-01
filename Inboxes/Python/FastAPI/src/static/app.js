
async function loadMessages() {
  const res = await fetch('/api/messages');
  const data = await res.json();
  const container = document.getElementById('messageList');
  if (data.messages.length === 0) {
    container.innerHTML = '<div class="empty">No messages</div>';
    return;
  }
  container.innerHTML = data.messages.map(m => `
    <div class="message" data-id="${m.id}">
      <button class="delete-btn" data-id="${m.id}">Delete</button>
      <h3>${m.subject || '(No subject)'}</h3>
      <div class="meta">From: ${m.sender} &middot; ${new Date(m.timestamp).toLocaleString()}</div>
      <div class="body">${m.body || '(No body)'}</div>
    </div>
  `).join('');
  container.querySelectorAll('.message').forEach(el => {
    el.addEventListener('click', (e) => {
      if (e.target.classList.contains('delete-btn')) return;
      el.classList.toggle('expanded');
    });
  });
  container.querySelectorAll('.delete-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      await fetch(`/api/messages/${btn.dataset.id}`, { method: 'DELETE' });
      loadMessages();
    });
  });
}

document.getElementById('sendBtn').addEventListener('click', async () => {
  const sender = document.getElementById('senderInput').value.trim();
  const subject = document.getElementById('subjectInput').value.trim();
  const body = document.getElementById('bodyInput').value.trim();
  if (!sender) return;
  await fetch('/api/messages', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ sender, subject, body })
  });
  document.getElementById('senderInput').value = '';
  document.getElementById('subjectInput').value = '';
  document.getElementById('bodyInput').value = '';
  loadMessages();
});

loadMessages();

