
    async function loadTasks() {
      const res = await fetch('/api/tasks');
      const tasks = await res.json();
      const container = document.getElementById('tasks');
      container.innerHTML = tasks.map(t => `
        <div class="task ${t.completed ? 'completed' : ''}">
          <strong>${t.id}.</strong> ${t.title}
          ${t.completed ? '<span>[x]</span>' : '<span>[ ]</span>'}
          <em>${t.created_at}</em>
          ${t.completed ? '' : `<button onclick="complete(${t.id})">Complete</button>`}
          <button onclick="del(${t.id})">Delete</button>
        </div>
      `).join('');
    }

    async function complete(id) {
      await fetch(`/api/tasks/${id}/complete`, { method: 'PUT' });
      loadTasks();
    }

    async function del(id) {
      await fetch(`/api/tasks/${id}`, { method: 'DELETE' });
      loadTasks();
    }

    document.getElementById('addForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const title = document.getElementById('title').value;
      const description = document.getElementById('description').value;
      await fetch('/api/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, description })
      });
      document.getElementById('title').value = '';
      document.getElementById('description').value = '';
      loadTasks();
    });

    loadTasks();
  
