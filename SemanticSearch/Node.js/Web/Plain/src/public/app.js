async function search() {
  const q = document.getElementById('query').value;
  const res = await fetch(`/api/search?q=${encodeURIComponent(q)}`);
  const data = await res.json();
  const results = document.getElementById('results');
  results.innerHTML = data.results.map(r => `<div><p>${r.document}</p><small>Distance: ${r.distance}</small></div>`).join('');
}