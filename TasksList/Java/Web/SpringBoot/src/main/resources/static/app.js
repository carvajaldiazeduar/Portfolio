function showMsg(text, type) {
  const msg = document.getElementById('msg');
  msg.textContent = text;
  msg.className = 'msg ' + type;
  setTimeout(() => { msg.style.display = 'none'; }, 3000);
}

async function loadTasks() {
  const res = await fetch('/api/tasks');
  const tasks = await res.json();
  renderTable(tasks);
}

async function addTask() {
  const title = document.getElementById('title').value.trim();
  const res = await fetch('/api/tasks', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({title})
  });
  if (res.ok) {
    showMsg('Task added!', 'success');
    document.getElementById('title').value = '';
    loadTasks();
  } else {
    const err = await res.json();
    showMsg(err.errors ? Object.values(err.errors)[0] : 'Failed to add task', 'error');
  }
}

async function toggleTask(id, completed) {
  const res = await fetch('/api/tasks/' + id, {
    method: 'PUT',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({completed})
  });
  if (res.ok) {
    loadTasks();
  } else {
    showMsg('Failed to update task', 'error');
  }
}

async function deleteTask(id) {
  if (!confirm('Delete this task?')) return;
  const res = await fetch('/api/tasks/' + id, { method: 'DELETE' });
  if (res.ok) {
    showMsg('Task deleted!', 'success');
    loadTasks();
  } else {
    showMsg('Failed to delete', 'error');
  }
}

function renderTable(tasks) {
  const tbody = document.getElementById('tasks-body');
  tbody.innerHTML = '';
  if (tasks.length === 0) {
    tbody.innerHTML = '<tr><td colspan="3" style="text-align:center;color:#999;">No tasks found.</td></tr>';
    return;
  }
  tasks.forEach((t) => {
    const tr = document.createElement('tr');
    tr.className = t.completed ? 'completed' : '';
    tr.innerHTML = `<td><input type="checkbox" ${t.completed ? 'checked' : ''} onchange="toggleTask(${t.id}, this.checked)"></td>
        <td>${t.title}</td>
        <td><button class="delete-btn" onclick="deleteTask(${t.id})">Delete</button></td>`;
    tbody.appendChild(tr);
  });
}

loadTasks();
