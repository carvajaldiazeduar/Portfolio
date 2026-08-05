const DatabaseAdapter = require('../DatabaseAdapter');

class SQLiteAdapter extends DatabaseAdapter {
  constructor(defaultDB) {
    super();
    this.defaultDB = defaultDB || 'data';
  }

  async connect() {
    const Database = require('better-sqlite3');
    this.db = new Database(process.env.DB_FILE || `${this.defaultDB}.db`);
    this.db.pragma('journal_mode = WAL');
  }

  _colType(col) {
    switch (col.type) {
      case 'string': case 'text': return 'TEXT';
      case 'integer': return 'INTEGER';
      case 'boolean': return 'INTEGER';
      case 'datetime': return 'TEXT';
      default: return 'TEXT';
    }
  }

  _colDef(col) {
    let def = `${col.name} ${this._colType(col)}`;
    if (col.required) def += ' NOT NULL';
    if (col.default !== undefined) {
      if (col.default === 'now') def += " DEFAULT (datetime('now'))";
      else if (typeof col.default === 'string') def += ` DEFAULT '${col.default}'`;
      else def += ` DEFAULT ${col.default}`;
    }
    return def;
  }

  async init(table, columns) {
    const cols = columns.map(c => this._colDef(c)).join(', ');
    this.db.exec(`CREATE TABLE IF NOT EXISTS ${table} (id INTEGER PRIMARY KEY AUTOINCREMENT, ${cols})`);
  }

  async getAll(table, options = {}) {
    let sql = `SELECT * FROM ${table}`;
    if (options.orderBy) sql += ` ORDER BY ${options.orderBy} ${options.orderDir || 'ASC'}`;
    if (options.limit) sql += ` LIMIT ${options.limit}`;
    return this.db.prepare(sql).all();
  }

  async getById(table, id) {
    return this.db.prepare(`SELECT * FROM ${table} WHERE id = ?`).get(id) || null;
  }

  async create(table, data) {
    const keys = Object.keys(data);
    const vals = Object.values(data);
    const placeholders = keys.map(() => '?').join(', ');
    const info = this.db.prepare(`INSERT INTO ${table} (${keys.join(', ')}) VALUES (${placeholders})`).run(...vals);
    return this.db.prepare(`SELECT * FROM ${table} WHERE id = ?`).get(info.lastInsertRowid);
  }

  async update(table, id, data) {
    const keys = Object.keys(data);
    const vals = Object.values(data);
    const setClause = keys.map(k => `${k} = ?`).join(', ');
    vals.push(id);
    this.db.prepare(`UPDATE ${table} SET ${setClause} WHERE id = ?`).run(...vals);
    return this.db.prepare(`SELECT * FROM ${table} WHERE id = ?`).get(id);
  }

  async delete(table, id) {
    const info = this.db.prepare(`DELETE FROM ${table} WHERE id = ?`).run(id);
    return { changes: info.changes };
  }

  async clear(table) {
    const info = this.db.prepare(`DELETE FROM ${table}`).run();
    return { changes: info.changes };
  }

  async search(table, field, query) {
    return this.db.prepare(`SELECT * FROM ${table} WHERE LOWER(${field}) LIKE ? ORDER BY id ASC`).all(`%${query.toLowerCase()}%`);
  }

  async close() {
    this.db.close();
  }
}
module.exports = SQLiteAdapter;
