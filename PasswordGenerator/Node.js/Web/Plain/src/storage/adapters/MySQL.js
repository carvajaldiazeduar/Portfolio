const DatabaseAdapter = require('../DatabaseAdapter');

class MySQLAdapter extends DatabaseAdapter {
  constructor(defaultDB) {
    super();
    this.defaultDB = defaultDB || 'mysql';
  }

  async connect() {
    const mysql = require('mysql2/promise');
    this.pool = mysql.createPool({
      host: process.env.DB_HOST || 'db',
      port: parseInt(process.env.DB_PORT || '3306'),
      database: process.env.DB_NAME || this.defaultDB,
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
    });
  }

  _colType(col) {
    switch (col.type) {
      case 'string': return 'VARCHAR(255)';
      case 'text': return 'TEXT';
      case 'integer': return 'INT';
      case 'boolean': return 'TINYINT';
      case 'datetime': return 'DATETIME';
      default: return 'VARCHAR(255)';
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
    await this.pool.execute(`CREATE TABLE IF NOT EXISTS ${table} (id INT AUTO_INCREMENT PRIMARY KEY, ${cols})`);
  }

  async getAll(table, options = {}) {
    let sql = `SELECT * FROM ${table}`;
    if (options.orderBy) sql += ` ORDER BY ${options.orderBy} ${options.orderDir || 'ASC'}`;
    if (options.limit) sql += ` LIMIT ${options.limit}`;
    const [r] = await this.pool.execute(sql);
    return r;
  }

  async getById(table, id) {
    const [r] = await this.pool.execute(`SELECT * FROM ${table} WHERE id = ?`, [id]);
    return r[0] || null;
  }

  async create(table, data) {
    const keys = Object.keys(data);
    const vals = Object.values(data);
    const placeholders = keys.map(() => '?').join(', ');
    const [r] = await this.pool.execute(
      `INSERT INTO ${table} (${keys.join(', ')}) VALUES (${placeholders})`,
      vals
    );
    const [rows] = await this.pool.execute(`SELECT * FROM ${table} WHERE id = ?`, [r.insertId]);
    return rows[0];
  }

  async update(table, id, data) {
    const keys = Object.keys(data);
    const vals = Object.values(data);
    const setClause = keys.map(k => `${k} = ?`).join(', ');
    vals.push(id);
    await this.pool.execute(`UPDATE ${table} SET ${setClause} WHERE id = ?`, vals);
    const [r] = await this.pool.execute(`SELECT * FROM ${table} WHERE id = ?`, [id]);
    return r[0] || null;
  }

  async delete(table, id) {
    const [r] = await this.pool.execute(`DELETE FROM ${table} WHERE id = ?`, [id]);
    return { changes: r.affectedRows };
  }

  async clear(table) {
    const [r] = await this.pool.execute(`DELETE FROM ${table}`);
    return { changes: r.affectedRows };
  }

  async search(table, field, query) {
    const [r] = await this.pool.execute(
      `SELECT * FROM ${table} WHERE LOWER(${field}) LIKE ? ORDER BY id ASC`,
      [`%${query.toLowerCase()}%`]
    );
    return r;
  }

  async close() {
    await this.pool.end();
  }
}
module.exports = MySQLAdapter;
