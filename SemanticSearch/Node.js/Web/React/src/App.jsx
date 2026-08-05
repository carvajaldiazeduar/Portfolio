import { useState } from 'react';

function App() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [message, setMessage] = useState('');

  const handleSearch = async (e) => {
    e.preventDefault();
    const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
    const data = await res.json();
    setResults(data.results || []);
  };

  const handleUpload = async (e) => {
    e.preventDefault();
    const formData = new FormData();
    formData.append('file', e.target.file.files[0]);
    const res = await fetch('/api/upload', { method: 'POST', body: formData });
    const data = await res.json();
    setMessage(data.message || 'Uploaded');
  };

  return (
    <main>
      <h1>Semantic Search</h1>
      <form onSubmit={handleUpload}>
        <input type="file" name="file" />
        <button type="submit">Upload</button>
      </form>
      <p>{message}</p>
      <form onSubmit={handleSearch}>
        <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search..." />
        <button type="submit">Search</button>
      </form>
      <div>
        {results.map((r, i) => (
          <div key={i}>
            <p>{r.document}</p>
            <small>Distance: {r.distance}</small>
          </div>
        ))}
      </div>
    </main>
  );
}

export default App;