function renderMessages(data) {
  const container = document.getElementById('messageList');
  if (data.length === 0) {
    container.innerHTML = '<div class="empty">No messages yet</div>';
    return;
  }
  container.innerHTML = '<table><thead><tr><th>Sender</th><th>Subject</th></tr></thead><tbody>' +
    data.map(m => `<tr><td>${m.sender}</td><td>${m.subject}</td></tr>`).join('') +
    '</tbody></table>';
}

document.getElementById('searchInput').addEventListener('input', async (e) => {
  const q = e.target.value.trim();
  if (!q) { location.reload(); return; }
  const res = await fetch('/messages/search?q=' + encodeURIComponent(q));
  renderMessages(await res.json());
});