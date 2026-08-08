
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
    const name = document.getElementById('name').value.trim();
    const phone = document.getElementById('phone').value.trim();
    const email = document.getElementById('email').value.trim();
    clearFieldFeedback();
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
            applyFieldFeedback(err.errors);
        } else {
            showMsg(err.error, 'error');
        }
    }
}

function clearFieldFeedback() {
    ['name', 'phone', 'email'].forEach((field) => {
        const input = document.getElementById(field);
        const msg = document.getElementById(field + '-error');
        input.classList.remove('invalid', 'valid');
        msg.textContent = '';
    });
}

function applyFieldFeedback(errors) {
    ['name', 'phone', 'email'].forEach((field) => {
        const input = document.getElementById(field);
        const msg = document.getElementById(field + '-error');
        if (errors[field]) {
            input.classList.remove('valid');
            input.classList.add('invalid');
            msg.textContent = errors[field];
        } else {
            input.classList.remove('invalid');
            input.classList.add('valid');
            msg.textContent = '';
        }
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

loadContacts();

