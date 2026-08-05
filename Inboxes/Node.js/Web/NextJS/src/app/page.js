'use client'

import { useState } from 'react'

export default function Home() {
  const [messages, setMessages] = useState([])
  const [from, setFrom] = useState('')
  const [subject, setSubject] = useState('')
  const [body, setBody] = useState('')
  const [view, setView] = useState('inbox')
  const [selected, setSelected] = useState(null)

  function sendMessage() {
    if (!from.trim() || !subject.trim() || !body.trim()) return
    setMessages([{ id: Date.now(), from, subject, body, read: false }, ...messages])
    setFrom('')
    setSubject('')
    setBody('')
  }

  function markRead(id) {
    setMessages(messages.map((m) => (m.id === id ? { ...m, read: true } : m)))
  }

  function deleteMessage(id) {
    setMessages(messages.filter((m) => m.id !== id))
    if (selected && selected.id === id) setSelected(null)
  }

  function openMessage(msg) {
    markRead(msg.id)
    setSelected(msg)
    setView('detail')
  }

  const unread = messages.filter((m) => !m.read).length

  return (
    <div className="container">
      <h1>Inboxes</h1>
      {view === 'inbox' && (
        <>
          <div className="compose">
            <h2>Send Message</h2>
            <div className="form-group">
              <label htmlFor="from">From</label>
              <input id="from" value={from} onChange={(e) => setFrom(e.target.value)} placeholder="Your name" />
            </div>
            <div className="form-group">
              <label htmlFor="subject">Subject</label>
              <input id="subject" value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Message subject" />
            </div>
            <div className="form-group">
              <label htmlFor="body">Body</label>
              <textarea id="body" value={body} onChange={(e) => setBody(e.target.value)} placeholder="Message body" rows={3} />
            </div>
            <button onClick={sendMessage}>Send</button>
          </div>
          <div className="inbox">
            <h2>Inbox ({unread} unread)</h2>
            {messages.length === 0 && <p className="empty">No messages.</p>}
            {messages.map((m) => (
              <div key={m.id} className={`msg-item ${!m.read ? 'unread' : ''}`} onClick={() => openMessage(m)}>
                <div className="msg-summary">
                  <strong>{m.from}</strong>
                  <span>{m.subject}</span>
                </div>
                <button className="delete" onClick={(e) => { e.stopPropagation(); deleteMessage(m.id) }}>Delete</button>
              </div>
            ))}
          </div>
        </>
      )}
      {view === 'detail' && selected && (
        <div className="detail">
          <button className="back" onClick={() => setView('inbox')}>Back</button>
          <h2>{selected.subject}</h2>
          <p className="meta">From: {selected.from}</p>
          <p className="body">{selected.body}</p>
          <button className="delete" onClick={() => { deleteMessage(selected.id); setView('inbox') }}>Delete</button>
        </div>
      )}
    </div>
  )
}
