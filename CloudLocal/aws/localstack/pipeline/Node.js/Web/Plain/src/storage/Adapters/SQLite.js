const Database = require('better-sqlite3');
const DatabaseAdapter = require('../DatabaseAdapter');

class SQLiteAdapter extends DatabaseAdapter {
  constructor() {
    super();
    this._db = null;
  }

  async connect() {
    const dbPath = process.env.DB_FILE || './pipeline.db';
    this._db = new Database(dbPath);
    this._db.pragma('journal_mode = WAL');
    console.log('Connected to SQLite');
  }

  async query(sql, params) {
    if (!this._db) await this.connect();
    const stmt = this._db.prepare(sql);
    return stmt.all(...(params || []));
  }

  async insert(table, data) {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const placeholders = columns.map(() => '?').join(', ');
    const columnNames = columns.join(', ');
    const sql = `INSERT INTO ${table} (${columnNames}) VALUES (${placeholders})`;
    const stmt = this._db.prepare(sql);
    const result = stmt.run(...values);
    return this.find(table, result.lastInsertRowid);
  }

  async update(table, id, data) {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const setClause = columns.map(col => `${col} = ?`).join(', ');
    const sql = `UPDATE ${table} SET ${setClause} WHERE id = ?`;
    this._db.prepare(sql).run(...values, id);
    return this.find(table, id);
  }

  async delete(table, id) {
    const sql = `DELETE FROM ${table} WHERE id = ?`;
    this._db.prepare(sql).run(id);
  }

  async find(table, id) {
    const sql = `SELECT * FROM ${table} WHERE id = ?`;
    const row = this._db.prepare(sql).get(id);
    return row || null;
  }

  async findAll(table) {
    const sql = `SELECT * FROM ${table}`;
    return this._db.prepare(sql).all();
  }

  async close() {
    if (this._db) {
      this._db.close();
      this._db = null;
    }
  }
}

module.exports = { SQLiteAdapter };
