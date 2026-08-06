class VectorStoreAdapter {
  async connect() { throw new Error('Not implemented'); }
  async addDocuments(documents, embeddings, metadata) { throw new Error('Not implemented'); }
  async search(queryEmbedding, nResults = 5) { throw new Error('Not implemented'); }
  async deleteCollection(collectionName) { throw new Error('Not implemented'); }
  async listCollections() { throw new Error('Not implemented'); }
  async close() { throw new Error('Not implemented'); }
}

module.exports = VectorStoreAdapter;