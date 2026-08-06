const VectorStoreAdapter = require('../VectorAdapter');

class ChromaDB extends VectorStoreAdapter {
  constructor() {
    super();
    this._client = null;
    this._collections = {};
  }

  async connect() {
    if (this._client) return;
    try {
      const chromadb = require('chromadb');
      const host = process.env.CHROMA_HOST || 'localhost';
      const port = parseInt(process.env.CHROMA_PORT || '8000');
      this._client = chromadb.HttpClient({ host, port });
    } catch {
      const chromadb = require('chromadb');
      this._client = chromadb.Client();
    }
  }

  async addDocuments(documents, embeddings, metadata) {
    await this.connect();
    const collectionName = process.env.VECTOR_COLLECTION || 'documents';
    if (!this._collections[collectionName]) {
      this._collections[collectionName] = await this._client.getOrCreateCollection(collectionName);
    }
    const collection = this._collections[collectionName];
    const ids = documents.map((_, i) => `doc_${i}`);
    await collection.add({ documents, embeddings, metadatas: metadata, ids });
  }

  async search(queryEmbedding, nResults = 5) {
    await this.connect();
    const collectionName = process.env.VECTOR_COLLECTION || 'documents';
    const collection = this._collections[collectionName];
    if (!collection) return [];
    const results = await collection.query({ queryEmbeddings: [queryEmbedding], nResults });
    return results.documents[0].map((doc, i) => ({
      document: doc,
      metadata: results.metadatas[0][i],
      distance: results.distances[0][i],
    }));
  }

  async deleteCollection(collectionName) {
    delete this._collections[collectionName];
    try {
      await this._client.deleteCollection(collectionName);
    } catch {}
  }

  async listCollections() {
    await this.connect();
    const collections = await this._client.listCollections();
    return collections.map((c) => c.name);
  }

  async close() {
    this._collections = {};
    this._client = null;
  }
}

module.exports = { ChromaDB };