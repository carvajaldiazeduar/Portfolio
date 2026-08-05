const { Client } = require('pg');
const DatabaseAdapter = require('../DatabaseAdapter');

class PostgreSQLAdapter extends DatabaseAdapter {
  constructor() {
    super();
    this._client = null;
  }

  async connect() {
    this._client = new Client({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      database: process.env.DB_NAME || 'pipeline_db',
      user: process.env.DB_USER || 'admin',
      password: process.env.DB_PASSWORD || 'admin',
    });
    await this._client.connect();
    console.log('Connected to PostgreSQL');
  }

  async query(sql, params) {
    if (!this._client) await this.connect();
    const result = await this._client.query(sql, params);
    return result.rows;
  }

  async insert(table, data) {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const placeholders = columns.map((_, i) => `$${i + 1}`).join(', ');
    const columnNames = columns.join(', ');
    const sql = `INSERT INTO ${table} (${columnNames}) VALUES (${placeholders}) RETURNING *`;
    const result = await this.query(sql, values);
    return result[0];
  }

  async update(table, id, data) {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const setClause = columns.map((col, i) => `${col} = $${i + 1}`).join(', ');
    const sql = `UPDATE ${table} SET ${setClause} WHERE id = $${columns.length + 1} RETURNING *`;
    const result = await this.query(sql, [...values, id]);
    return result[0];
  }

  async delete(table, id) {
    const sql = `DELETE FROM ${table} WHERE id = $1`;
    await this.query(sql, [id]);
  }

  async find(table, id) {
    const sql = `SELECT * FROM ${table} WHERE id = $1`;
    const result = await this.query(sql, [id]);
    return result[0] || null;
  }

  async findAll(table) {
    const sql = `SELECT * FROM ${table}`;
    return this.query(sql);
  }

  async close() {
    if (this._client) {
      await this._client.end();
      this._client = null;
    }
  }
}

module.exports = { PostgreSQLAdapter };
