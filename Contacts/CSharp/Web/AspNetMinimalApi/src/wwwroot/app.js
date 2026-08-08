function showMsg(text, type) {
  const msg = document.getElementById('msg');
  msg.textContent = text;
  msg.className = 'msg ' + type;
  setTimeout(() => { msg.style.display = 'none'; }, 3000);
}

async function loadContacts() {
  document.getElementById('search').value = '';
  const res = await fetch('/api/contacts');
  const contacts = await res.json();
  renderTable(contacts);
}

async function addContact() {
  clearFieldState();
  const name = document.getElementById('name').value.trim();
  const phone = document.getElementById('phone').value.trim();
  const email = document.getElementById('email').value.trim();
  const res = await fetch('/api/contacts', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({name, phone, email})
  });
  if (res.ok) {
    showMsg('Contact added!', 'success');
    document.getElementById('name').value = '';
    document.getElementById('phone').value = '';
    document.getElementById('email').value = '';
    loadContacts();
  } else {
    const err = await res.json();
    if (err.errors) {
      applyFieldErrors(err.errors);
      showMsg('Please fix the highlighted fields', 'error');
    } else {
      showMsg(err.error || 'Failed to add contact', 'error');
    }
  }
}

function clearFieldState() {
  ['name', 'phone', 'email'].forEach((field) => {
    const input = document.getElementById(field);
    const msg = document.getElementById(field + '-msg');
    input.classList.remove('is-invalid', 'is-valid');
    msg.textContent = '';
  });
}

function applyFieldErrors(errors) {
  ['name', 'phone', 'email'].forEach((field) => {
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
  ['name', 'phone', 'email'].forEach((field) => {
    document.getElementById(field).addEventListener('input', () => {
      const input = document.getElementById(field);
      const msg = document.getElementById(field + '-msg');
      input.classList.remove('is-invalid');
      msg.textContent = '';
    });
  });
}

async function searchContacts() {
  const q = document.getElementById('search').value.trim();
  if (!q) { loadContacts(); return; }
  const res = await fetch('/api/contacts/search?q=' + encodeURIComponent(q));
  const contacts = await res.json();
  renderTable(contacts);
}

async function deleteContact(index) {
  if (!confirm('Delete this contact?')) return;
  const res = await fetch('/api/contacts/' + index, { method: 'DELETE' });
  if (res.ok) {
    showMsg('Contact deleted!', 'success');
    loadContacts();
  } else {
    showMsg('Failed to delete', 'error');
  }
}

function renderTable(contacts) {
  const tbody = document.getElementById('contacts-body');
  tbody.innerHTML = '';
  if (contacts.length === 0) {
    tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:#999;">No contacts found.</td></tr>';
    return;
  }
  contacts.forEach((c, i) => {
    const tr = document.createElement('tr');
    tr.innerHTML = `<td>${c.name}</td><td>${c.phone || ''}</td><td>${c.email || ''}</td>
        <td><button class="delete-btn" onclick="deleteContact(${i})">Delete</button></td>`;
    tbody.appendChild(tr);
  });
}

bindClearInvalid();
loadContacts();
