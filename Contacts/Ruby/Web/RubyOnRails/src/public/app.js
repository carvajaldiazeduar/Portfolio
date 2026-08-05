function renderContacts(data) {
  const container = document.getElementById('contactList');
  if (data.length === 0) {
    container.innerHTML = '<div class="empty">No contacts yet</div>';
    return;
  }
  container.innerHTML = '<table><thead><tr><th>Name</th><th>Phone</th><th>Email</th></tr></thead><tbody>' +
    data.map(c => `<tr><td>${c.name}</td><td>${c.phone}</td><td>${c.email}</td></tr>`).join('') +
    '</tbody></table>';
}

document.getElementById('searchInput').addEventListener('input', async (e) => {
  const q = e.target.value.trim();
  if (!q) { location.reload(); return; }
  const res = await fetch('/contacts/search?q=' + encodeURIComponent(q));
  renderContacts(await res.json());
});