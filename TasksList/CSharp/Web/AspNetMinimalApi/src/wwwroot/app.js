
        async function loadTasks() {
            const res = await fetch("/api/tasks");
            const tasks = await res.json();
            const div = document.getElementById("tasks");
            div.innerHTML = tasks.map(t => `
                <div class="task ${t.completed ? 'completed' : ''}">
                    <strong>${t.title}</strong> ${t.completed ? '<span class="completed-label">✓</span>' : ''}
                    <p>${t.description || ''}</p>
                    <small>${t.createdAt || ''}</small>
                    <div class="task-actions">
                        ${!t.completed ? `<button onclick="completeTask(${t.id})">Complete</button>` : ''}
                        <button onclick="deleteTask(${t.id})">Delete</button>
                    </div>
                </div>
            `).join("");
        }
        async function addTask() {
            const title = document.getElementById("title").value;
            const description = document.getElementById("description").value;
            await fetch("/api/tasks", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ title, description }),
            });
            document.getElementById("title").value = "";
            document.getElementById("description").value = "";
            loadTasks();
        }
        async function completeTask(id) {
            await fetch(`/api/tasks/${id}/complete`, { method: "PUT" });
            loadTasks();
        }
        async function deleteTask(id) {
            await fetch(`/api/tasks/${id}`, { method: "DELETE" });
            loadTasks();
        }
        loadTasks();
    
