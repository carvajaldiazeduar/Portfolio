export default function Home() {
  return (
    <main>
      <h1>Semantic Search</h1>
      <form action="/api/upload" method="post" encType="multipart/form-data">
        <input type="file" name="file" />
        <button type="submit">Upload</button>
      </form>
      <form action="/api/search">
        <input name="q" placeholder="Search..." />
        <button type="submit">Search</button>
      </form>
    </main>
  );
}