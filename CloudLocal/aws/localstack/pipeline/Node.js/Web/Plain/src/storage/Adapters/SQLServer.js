const { Connection, Request } = require('tedious');
const DatabaseAdapter = require('../DatabaseAdapter');

class SQLServerAdapter extends DatabaseAdapter {
  constructor() {
    super();
    this._connection = null;
    this._connectPromise = null;
  }

  _getConfig() {
    return {
      server: process.env.DB_HOST || 'localhost',
      options: {
        port: parseInt(process.env.DB_PORT || '1433'),
        database: process.env.DB_NAME || 'pipeline_db',
        encrypt: false,
        trustServerCertificate: true,
      },
      authentication: {
        type: 'default',
        options: {
          userName: process.env.DB_USER || 'admin',
          password: process.env.DB_PASSWORD || 'admin',
        },
      },
    };
  }

  async connect() {
    if (this._connectPromise) return this._connectPromise;
    this._connectPromise = new Promise((resolve, reject) => {
      this._connection = new Connection(this._getConfig());
      this._connection.on('connect', (err) => {
        if (err) reject(err);
        else {
          console.log('Connected to SQL Server');
          resolve();
        }
      });
      this._connection.on('error', (err) => {
        reject(err);
      });
      this._connection.connect();
    });
    return this._connectPromise;
  }

  async query(sql, params) {
    if (!this._connection) await this.connect();
    return new Promise((resolve, reject) => {
      const request = new Request(sql, (err, rowCount) => {
        if (err) reject(err);
        else resolve([]);
      });
      const rows = [];
      request.on('row', (columns) => {
        const row = {};
        columns.forEach((col) => {
          row[col.metadata.colName] = col.value;
        });
        rows.push(row);
      });
      request.on('doneInProc', (rowCount) => {
        resolve(rows);
      });
      if (params) {
        params.forEach((param, i) => {
          request.addParameter(`p${i}`, reqType(param), param);
        });
      }
      this._connection.execSql(request);
    });
  }

  async insert(table, data) {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const columnNames = columns.join(', ');
    const placeholders = columns.map((_, i) => `@p${i}`).join(', ');
    const sql = `INSERT INTO ${table} (${columnNames}) VALUES (${placeholders}); SELECT SCOPE_IDENTITY() AS id`;
    const result = await this.query(sql, values);
    return this.find(table, result[0].id);
  }

  async update(table, id, data) {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const setClause = columns.map((col, i) => `${col} = @p${i}`).join(', ');
    const sql = `UPDATE ${table} SET ${setClause} WHERE id = @p${columns.length}`;
    await this.query(sql, [...values, id]);
    return this.find(table, id);
  }

  async delete(table, id) {
    const sql = `DELETE FROM ${table} WHERE id = @p0`;
    await this.query(sql, [id]);
  }

  async find(table, id) {
    const sql = `SELECT * FROM ${table} WHERE id = @p0`;
    const rows = await this.query(sql, [id]);
    return rows[0] || null;
  }

  async findAll(table) {
    const sql = `SELECT * FROM ${table}`;
    return this.query(sql);
  }

  async close() {
    if (this._connection) {
      this._connection.close();
      this._connection = null;
      this._connectPromise = null;
    }
  }
}

function reqType(val) {
  if (typeof val === 'number') return 'Int4';
  if (typeof val === 'boolean') return 'Bit';
  return 'NVarChar';
}

module.exports = { SQLServerAdapter };
