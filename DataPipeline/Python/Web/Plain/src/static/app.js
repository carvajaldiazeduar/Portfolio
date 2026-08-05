async function loadPipelines() {
  const res = await fetch('/api/pipelines');
  const data = await res.json();
  document.getElementById('pipelines').innerHTML = data.pipelines.map(p => `<div>${p}</div>`).join('');
}
loadPipelines();