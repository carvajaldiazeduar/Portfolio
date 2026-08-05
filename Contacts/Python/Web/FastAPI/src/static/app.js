
async function loadContacts() {
  const res = await fetch('/api/contacts');
  const data = await res.json();
  const container = document.getElementById('contactList');
  if (data.contacts.length === 0) {
    container.innerHTML = '<div class="empty">No contacts yet</div>';
    return;
  }
  container.innerHTML = `<table><thead><tr><th>Name</th><th>Phone</th><th>Email</th><th></th></tr></thead><tbody>${data.contacts.map(c => `<tr><td>${c.name}</td><td>${c.phone}</td><td>${c.email}</td><td><button class="delete-btn" data-id="${c.id}">Delete</button></td></tr>`).join('')}</tbody></table>`;
  container.querySelectorAll('.delete-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      await fetch(`/api/contacts/${btn.dataset.id}`, { method: 'DELETE' });
      loadContacts();
    });
  });
}

document.getElementById('addBtn').addEventListener('click', async () => {
  const name = document.getElementById('nameInput').value.trim();
  const phone = document.getElementById('phoneInput').value.trim();
  const email = document.getElementById('emailInput').value.trim();
  if (!name) return;
  await fetch('/api/contacts', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, phone, email })
  });
  document.getElementById('nameInput').value = '';
  document.getElementById('phoneInput').value = '';
  document.getElementById('emailInput').value = '';
  loadContacts();
});

loadContacts();

