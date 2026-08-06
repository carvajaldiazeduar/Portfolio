const VectorStoreAdapter = require('../VectorAdapter');

class Pinecone extends VectorStoreAdapter {
  constructor() {
    super();
    this._index = null;
  }

  async connect() {
    if (this._index) return;
    const pinecone = require('@pinecone-database/pinecone');
    const apiKey = process.env.PINECONE_API_KEY || '';
    const client = new pinecone.Pinecone({ apiKey });
    const indexName = process.env.PINECONE_INDEX || 'documents';
    this._index = client.Index(indexName);
  }

  async addDocuments(documents, embeddings, metadata) {
    await this.connect();
    const vectors = documents.map((doc, i) => ({
      id: `doc_${i}`,
      values: embeddings[i],
      metadata: { ...metadata[i], text: doc },
    }));
    await this._index.upsert({ vectors });
  }

  async search(queryEmbedding, nResults = 5) {
    await this.connect();
    const results = await this._index.query({ vector: queryEmbedding, topK: nResults, includeMetadata: true });
    return results.matches.map((match) => ({
      document: match.metadata?.text || '',
      metadata: { ...match.metadata, text: undefined },
      distance: match.score,
    }));
  }

  async deleteCollection() {}

  async listCollections() {
    try {
      const pinecone = require('@pinecone-database/pinecone');
      const apiKey = process.env.PINECONE_API_KEY || '';
      const client = new pinecone.Pinecone({ apiKey });
      return (await client.listIndexes()).map((i) => i.name);
    } catch {
      return [];
    }
  }

  async close() {
    this._index = null;
  }
}

module.exports = { Pinecone };