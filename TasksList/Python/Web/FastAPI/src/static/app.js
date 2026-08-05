
async function loadTasks() {
  const res = await fetch('/api/tasks');
  const data = await res.json();
  const container = document.getElementById('taskList');
  if (data.tasks.length === 0) {
    container.innerHTML = '<div class="empty">No tasks yet</div>';
    return;
  }
  container.innerHTML = data.tasks.map(t => `
    <div class="task">
      <span class="title ${t.completed ? 'done' : ''}">${t.title}</span>
      <button class="toggle-btn" data-id="${t.id}">${t.completed ? 'Undo' : 'Done'}</button>
      <button class="delete-btn" data-id="${t.id}">Delete</button>
    </div>
  `).join('');
  container.querySelectorAll('.toggle-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      await fetch(`/api/tasks/${btn.dataset.id}/complete`, { method: 'PUT' });
      loadTasks();
    });
  });
  container.querySelectorAll('.delete-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      await fetch(`/api/tasks/${btn.dataset.id}`, { method: 'DELETE' });
      loadTasks();
    });
  });
}

document.getElementById('addBtn').addEventListener('click', async () => {
  const title = document.getElementById('taskInput').value.trim();
  if (!title) return;
  await fetch('/api/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title })
  });
  document.getElementById('taskInput').value = '';
  loadTasks();
});

document.getElementById('taskInput').addEventListener('keydown', (e) => {
  if (e.key === 'Enter') document.getElementById('addBtn').click();
});

loadTasks();

