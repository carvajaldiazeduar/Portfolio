
        const tbody = document.getElementById('contactsBody');
        const empty = document.getElementById('empty');

        async function loadContacts() {
            const r = await fetch('/api/contacts');
            const contacts = await r.json();
            tbody.innerHTML = contacts.map(c => '<tr><td>' + esc(c.name) + '</td><td>' + esc(c.email) + '</td><td>' + esc(c.phone) + '</td><td><button class=\"deleteBtn\" data-id=\"' + c.id + '\">Delete</button></td></tr>').join('');
            empty.style.display = contacts.length ? 'none' : 'block';
            document.querySelectorAll('.deleteBtn').forEach(btn => btn.addEventListener('click', async () => {
                await fetch('/api/contacts/' + btn.dataset.id, { method: 'DELETE' });
                loadContacts();
            }));
        }

        function esc(s) { const d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

        function clearFieldErrors() {
            ['name', 'email', 'phone'].forEach(f => {
                const input = document.getElementById(f + 'Input');
                const errEl = document.getElementById(f + 'Error');
                input.classList.remove('invalid', 'valid');
                errEl.textContent = '';
            });
        }

        function markFieldErrors(errors) {
            clearFieldErrors();
            ['name', 'email', 'phone'].forEach(f => {
                const input = document.getElementById(f + 'Input');
                const errEl = document.getElementById(f + 'Error');
                if (errors[f]) {
                    input.classList.add('invalid');
                    errEl.textContent = errors[f];
                } else {
                    input.classList.add('valid');
                }
            });
        }

        document.getElementById('addBtn').addEventListener('click', async () => {
            const name = document.getElementById('nameInput').value.trim();
            const email = document.getElementById('emailInput').value.trim();
            const phone = document.getElementById('phoneInput').value.trim();
            const res = await fetch('/api/contacts', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name: name,
                    email: email,
                    phone: phone
                })
            });
            const data = await res.json();
            if (res.ok) {
                clearFieldErrors();
                document.getElementById('nameInput').value = '';
                document.getElementById('emailInput').value = '';
                document.getElementById('phoneInput').value = '';
                loadContacts();
            } else if (data.errors) {
                markFieldErrors(data.errors);
            }
        });

        loadContacts();
    
