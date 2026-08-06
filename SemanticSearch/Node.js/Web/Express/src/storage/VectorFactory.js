const { ChromaDB } = require('./adapters/ChromaDB');
const { Pinecone } = require('./adapters/Pinecone');
const { PgVector } = require('./adapters/PgVector');

function createVectorStore() {
  const driver = process.env.VECTOR_DRIVER || 'chromadb';
  switch (driver) {
    case 'pinecone':
      return new Pinecone();
    case 'pgvector':
      return new PgVector();
    case 'chromadb':
    default:
      return new ChromaDB();
  }
}

module.exports = { createVectorStore };