
        async function loadTasks() {
            const r = await fetch('/api/tasks');
            const tasks = await r.json();
            const list = document.getElementById('tasksList');
            list.innerHTML = tasks.map(t => '<li><span class=\"title' + (t.completed ? ' done' : '') + '\">' + esc(t.title) + '</span><button class=\"completeBtn' + (t.completed ? ' undo' : '') + '\" data-id=\"' + t.id + '\">' + (t.completed ? 'Undo' : 'Done') + '</button><button class=\"deleteBtn\" data-id=\"' + t.id + '\">Delete</button></li>').join('');
            document.getElementById('empty').style.display = tasks.length ? 'none' : 'block';
            document.getElementById('counter').textContent = tasks.length + ' task' + (tasks.length !== 1 ? 's' : '');
            list.querySelectorAll('.completeBtn').forEach(btn => btn.addEventListener('click', async () => {
                await fetch('/api/tasks/' + btn.dataset.id + '/complete', { method: 'PUT' });
                loadTasks();
            }));
            list.querySelectorAll('.deleteBtn').forEach(btn => btn.addEventListener('click', async () => {
                await fetch('/api/tasks/' + btn.dataset.id, { method: 'DELETE' });
                loadTasks();
            }));
        }
        function esc(s) { const d = document.createElement('div'); d.textContent = s; return d.innerHTML; }
        document.getElementById('addBtn').addEventListener('click', async () => {
            const title = document.getElementById('titleInput').value;
            if (!title.trim()) return;
            await fetch('/api/tasks', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ title }) });
            document.getElementById('titleInput').value = '';
            loadTasks();
        });
        document.getElementById('titleInput').addEventListener('keydown', e => { if (e.key === 'Enter') document.getElementById('addBtn').click(); });
        loadTasks();
    
