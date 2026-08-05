const DatabaseAdapter = require('../DatabaseAdapter');

class SQLServerAdapter extends DatabaseAdapter {
  constructor(defaultDB) {
    super();
    this.defaultDB = defaultDB || 'mssql';
  }

  async connect() {
    const sql = require('mssql');
    this.sql = sql;
    this.conn = await sql.connect({
      server: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '1433'),
      database: process.env.DB_NAME || this.defaultDB,
      user: process.env.DB_USER || 'sa',
      password: process.env.DB_PASSWORD || 'Password123',
    });
  }

  _colType(col) {
    switch (col.type) {
      case 'string': return 'NVARCHAR(255)';
      case 'text': return 'NVARCHAR(MAX)';
      case 'integer': return 'INT';
      case 'boolean': return 'INT';
      case 'datetime': return 'DATETIME';
      default: return 'NVARCHAR(255)';
    }
  }

  _colDef(col) {
    let def = `${col.name} ${this._colType(col)}`;
    if (col.required) def += ' NOT NULL';
    if (col.default !== undefined) {
      if (col.default === 'now') def += ' DEFAULT GETDATE()';
      else if (typeof col.default === 'string') def += ` DEFAULT '${col.default}'`;
      else def += ` DEFAULT ${col.default}`;
    }
    return def;
  }

  async init(table, columns) {
    const cols = columns.map(c => this._colDef(c)).join(', ');
    const check = await new this.sql.Request().query(
      `SELECT * FROM sysobjects WHERE name='${table}' AND xtype='U'`
    );
    if (check.recordset.length === 0) {
      await new this.sql.Request().query(
        `CREATE TABLE ${table} (id INT IDENTITY(1,1) PRIMARY KEY, ${cols})`
      );
    }
  }

  async getAll(table, options = {}) {
    let sql = `SELECT * FROM ${table}`;
    if (options.orderBy) sql += ` ORDER BY ${options.orderBy} ${options.orderDir || 'ASC'}`;
    if (options.limit) sql += ` OFFSET 0 ROWS FETCH NEXT ${options.limit} ROWS ONLY`;
    const r = await new this.sql.Request().query(sql);
    return r.recordset;
  }

  async getById(table, id) {
    const r = await new this.sql.Request()
      .input('id', id)
      .query(`SELECT * FROM ${table} WHERE id = @id`);
    return r.recordset[0] || null;
  }

  async create(table, data) {
    const keys = Object.keys(data);
    const vals = Object.values(data);
    const request = new this.sql.Request();
    vals.forEach((v, i) => request.input(`p${i + 1}`, v));
    const cols = keys.join(', ');
    const params = keys.map((_, i) => `@p${i + 1}`).join(', ');
    const r = await request.query(
      `INSERT INTO ${table} (${cols}) VALUES (${params}); SELECT * FROM ${table} WHERE id = SCOPE_IDENTITY();`
    );
    return r.recordset[0];
  }

  async update(table, id, data) {
    const keys = Object.keys(data);
    const vals = Object.values(data);
    const setClause = keys.map((k, i) => `${k} = @p${i + 1}`).join(', ');
    const request = new this.sql.Request();
    vals.forEach((v, i) => request.input(`p${i + 1}`, v));
    request.input('id', id);
    await request.query(`UPDATE ${table} SET ${setClause} WHERE id = @id`);
    const r = await new this.sql.Request()
      .input('id', id)
      .query(`SELECT * FROM ${table} WHERE id = @id`);
    return r.recordset[0] || null;
  }

  async delete(table, id) {
    const request = new this.sql.Request().input('id', id);
    const r = await request.query(`DELETE FROM ${table} WHERE id = @id`);
    return { changes: r.rowsAffected[0] };
  }

  async clear(table) {
    const r = await new this.sql.Request().query(`DELETE FROM ${table}`);
    return { changes: r.rowsAffected[0] };
  }

  async search(table, field, query) {
    const r = await new this.sql.Request()
      .input('q', `%${query.toLowerCase()}%`)
      .query(`SELECT * FROM ${table} WHERE LOWER(${field}) LIKE @q ORDER BY id ASC`);
    return r.recordset;
  }

  async close() {
    await this.conn.close();
  }
}
module.exports = SQLServerAdapter;
