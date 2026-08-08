
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

function clearFieldErrors() {
    ['name', 'phone', 'email'].forEach((f) => {
        const input = document.getElementById(f);
        const errEl = document.getElementById(f + '-error');
        input.classList.remove('invalid', 'valid');
        errEl.textContent = '';
    });
}

function markFieldErrors(errors) {
    clearFieldErrors();
    ['name', 'phone', 'email'].forEach((f) => {
        const input = document.getElementById(f);
        const errEl = document.getElementById(f + '-error');
        if (errors[f]) {
            input.classList.add('invalid');
            errEl.textContent = errors[f];
        } else {
            input.classList.add('valid');
        }
    });
}

async function addContact() {
    const name = document.getElementById('name').value.trim();
    const phone = document.getElementById('phone').value.trim();
    const email = document.getElementById('email').value.trim();
    const res = await fetch('/api/contacts', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({name, phone, email})
    });
    if (res.ok) {
        clearFieldErrors();
        showMsg('Contact added!', 'success');
        document.getElementById('name').value = '';
        document.getElementById('phone').value = '';
        document.getElementById('email').value = '';
        loadContacts();
    } else {
        const err = await res.json();
        if (err.errors) {
            markFieldErrors(err.errors);
        } else {
            showMsg(err.error, 'error');
        }
    }
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

loadContacts();

