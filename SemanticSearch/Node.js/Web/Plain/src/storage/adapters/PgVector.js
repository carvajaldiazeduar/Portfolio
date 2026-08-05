const { Pool } = require('pg');
const VectorStoreAdapter = require('../VectorAdapter');

class PgVector extends VectorStoreAdapter {
  constructor() {
    super();
    this._pool = null;
  }

  async connect() {
    if (this._pool) return;
    this._pool = new Pool({
      host: process.env.DB_HOST || 'db',
      port: parseInt(process.env.DB_PORT || '5432'),
      database: process.env.DB_NAME || 'semantic_search',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
    });
    await this._pool.query('CREATE EXTENSION IF NOT EXISTS vector');
  }

  _table(collectionName) {
    return `vector_${collectionName.replace(/-/g, '_')}`;
  }

  async addDocuments(documents, embeddings, metadata) {
    await this.connect();
    const collectionName = process.env.VECTOR_COLLECTION || 'documents';
    const table = this._table(collectionName);
    await this._pool.query(`CREATE TABLE IF NOT EXISTS ${table} (id SERIAL PRIMARY KEY, document TEXT, embedding vector, metadata JSONB)`);
    for (let i = 0; i < documents.length; i++) {
      await this._pool.query(
        `INSERT INTO ${table} (document, embedding, metadata) VALUES ($1, $2, $3)`,
        [documents[i], embeddings[i], JSON.stringify(metadata[i])]
      );
    }
  }

  async search(queryEmbedding, nResults = 5) {
    await this.connect();
    const collectionName = process.env.VECTOR_COLLECTION || 'documents';
    const table = this._table(collectionName);
    const res = await this._pool.query(
      `SELECT document, metadata, embedding <=> $1::vector AS distance FROM ${table} ORDER BY embedding <=> $1::vector LIMIT $2`,
      [JSON.stringify(queryEmbedding), nResults]
    );
    return res.rows.map((row) => ({
      document: row.document,
      metadata: row.metadata,
      distance: row.distance,
    }));
  }

  async deleteCollection(collectionName) {
    const table = this._table(collectionName);
    await this._pool.query(`DROP TABLE IF EXISTS ${table}`);
  }

  async listCollections() {
    await this.connect();
    const res = await this._pool.query("SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'vector_%'");
    return res.rows.map((row) => row.table_name);
  }

  async close() {
    if (this._pool) {
      await this._pool.end();
      this._pool = null;
    }
  }
}

module.exports = { PgVector };