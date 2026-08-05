
        let currentId = null;
        async function loadMessages() {
            const r = await fetch('/api/messages');
            const messages = await r.json();
            const list = document.getElementById('messagesList');
            list.innerHTML = messages.map(m => '<li data-id=\"' + m.id + '\"><div class=\"subject\">' + esc(m.subject) + '</div><div class=\"preview\">' + esc(m.body.substring(0,50)) + (m.body.length>50?'...':'') + '</div><div class=\"time\">' + new Date(m.created_at).toLocaleString() + '</div></li>').join('');
            document.getElementById('empty').style.display = messages.length ? 'none' : 'block';
            list.querySelectorAll('li').forEach(li => li.addEventListener('click', () => showMessage(parseInt(li.dataset.id))));
        }
        async function showMessage(id) {
            const r = await fetch('/api/messages/' + id);
            const m = await r.json();
            currentId = m.id;
            document.getElementById('detailSubject').textContent = m.subject;
            document.getElementById('detailBody').textContent = m.body;
            document.getElementById('detailTime').textContent = new Date(m.created_at).toLocaleString();
            document.getElementById('detail').style.display = 'block';
        }
        function esc(s) { const d = document.createElement('div'); d.textContent = s; return d.innerHTML; }
        document.getElementById('sendBtn').addEventListener('click', async () => {
            const subject = document.getElementById('subjectInput').value;
            const body = document.getElementById('bodyInput').value;
            if (!subject.trim() || !body.trim()) return;
            await fetch('/api/messages', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({subject,body}) });
            document.getElementById('subjectInput').value = '';
            document.getElementById('bodyInput').value = '';
            loadMessages();
        });
        document.getElementById('detailDelBtn').addEventListener('click', async () => {
            if (currentId === null) return;
            await fetch('/api/messages/' + currentId, { method: 'DELETE' });
            document.getElementById('detail').style.display = 'none'; currentId = null;
            loadMessages();
        });
        document.getElementById('detailCloseBtn').addEventListener('click', () => { document.getElementById('detail').style.display = 'none'; currentId = null; });
        loadMessages();
    
