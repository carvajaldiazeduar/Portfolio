'use client'

import { useState } from 'react'

export default function Home() {
  const [tasks, setTasks] = useState([])
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')

  function addTask() {
    if (!title.trim()) return
    setTasks([...tasks, { id: Date.now(), title, description, completed: false }])
    setTitle('')
    setDescription('')
  }

  function toggleComplete(id) {
    setTasks(tasks.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t)))
  }

  function deleteTask(id) {
    setTasks(tasks.filter((t) => t.id !== id))
  }

  return (
    <div className="container">
      <h1>Tasks List</h1>
      <div className="form">
        <div className="form-group">
          <label htmlFor="title">Title</label>
          <input id="title" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Task title" />
        </div>
        <div className="form-group">
          <label htmlFor="description">Description</label>
          <input id="description" value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Description (optional)" />
        </div>
        <button onClick={addTask}>Add Task</button>
      </div>
      <div className="list">
        {tasks.length === 0 && <p className="empty">No tasks yet.</p>}
        {tasks.map((t) => (
          <div key={t.id} className={`task ${t.completed ? 'done' : ''}`}>
            <div className="task-info">
              <strong>{t.title}</strong>
              {t.description && <span>{t.description}</span>}
            </div>
            <div className="task-actions">
              <button className="toggle" onClick={() => toggleComplete(t.id)}>
                {t.completed ? 'Undo' : 'Complete'}
              </button>
              <button className="delete" onClick={() => deleteTask(t.id)}>Delete</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
