const { Pool } = require('pg');
const DatabaseAdapter = require('../DatabaseAdapter');

class PostgreSQLAdapter extends DatabaseAdapter {
  constructor(defaultDB) {
    super();
    this.defaultDB = defaultDB || 'postgres';
  }

  async connect() {
    this.pool = new Pool({
      host: process.env.DB_HOST || 'db',
      port: parseInt(process.env.DB_PORT || '5432'),
      database: process.env.DB_NAME || this.defaultDB,
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
    });
  }

  _colType(col) {
    switch (col.type) {
      case 'string': case 'text': return 'TEXT';
      case 'integer': return 'INTEGER';
      case 'boolean': return 'INTEGER';
      case 'datetime': return 'TIMESTAMP';
      default: return 'TEXT';
    }
  }

  _colDef(col) {
    let def = `${col.name} ${this._colType(col)}`;
    if (col.required) def += ' NOT NULL';
    if (col.default !== undefined) {
      if (col.default === 'now') def += ' DEFAULT CURRENT_TIMESTAMP';
      else if (typeof col.default === 'string') def += ` DEFAULT '${col.default}'`;
      else def += ` DEFAULT ${col.default}`;
    }
    return def;
  }

  async init(table, columns) {
    const cols = columns.map(c => this._colDef(c)).join(', ');
    await this.pool.query(`CREATE TABLE IF NOT EXISTS ${table} (id SERIAL PRIMARY KEY, ${cols})`);
  }

  _params(keys) {
    return keys.map((_, i) => `$${i + 1}`);
  }

  async getAll(table, options = {}) {
    let sql = `SELECT * FROM ${table}`;
    if (options.orderBy) sql += ` ORDER BY ${options.orderBy} ${options.orderDir || 'ASC'}`;
    if (options.limit) sql += ` LIMIT ${options.limit}`;
    const r = await this.pool.query(sql);
    return r.rows;
  }

  async getById(table, id) {
    const r = await this.pool.query(`SELECT * FROM ${table} WHERE id = $1`, [id]);
    return r.rows[0] || null;
  }

  async create(table, data) {
    const keys = Object.keys(data);
    const vals = Object.values(data);
    const r = await this.pool.query(
      `INSERT INTO ${table} (${keys.join(', ')}) VALUES (${this._params(keys).join(', ')}) RETURNING *`,
      vals
    );
    return r.rows[0];
  }

  async update(table, id, data) {
    const keys = Object.keys(data);
    const vals = Object.values(data);
    const setClause = keys.map((k, i) => `${k} = $${i + 1}`).join(', ');
    vals.push(id);
    const r = await this.pool.query(
      `UPDATE ${table} SET ${setClause} WHERE id = $${keys.length + 1} RETURNING *`,
      vals
    );
    return r.rows[0] || null;
  }

  async delete(table, id) {
    const r = await this.pool.query(`DELETE FROM ${table} WHERE id = $1`, [id]);
    return { changes: r.rowCount };
  }

  async clear(table) {
    const r = await this.pool.query(`DELETE FROM ${table}`);
    return { changes: r.rowCount };
  }

  async search(table, field, query) {
    const r = await this.pool.query(
      `SELECT * FROM ${table} WHERE LOWER(${field}) LIKE $1 ORDER BY id ASC`,
      [`%${query.toLowerCase()}%`]
    );
    return r.rows;
  }

  async close() {
    await this.pool.end();
  }
}
module.exports = PostgreSQLAdapter;
