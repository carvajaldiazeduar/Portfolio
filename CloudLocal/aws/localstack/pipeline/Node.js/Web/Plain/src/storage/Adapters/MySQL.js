const mysql = require('mysql2/promise');
const DatabaseAdapter = require('../DatabaseAdapter');

class MySQLAdapter extends DatabaseAdapter {
  constructor() {
    super();
    this._connection = null;
  }

  async connect() {
    this._connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '3306'),
      database: process.env.DB_NAME || 'pipeline_db',
      user: process.env.DB_USER || 'admin',
      password: process.env.DB_PASSWORD || 'admin',
    });
    console.log('Connected to MySQL');
  }

  async query(sql, params) {
    if (!this._connection) await this.connect();
    const [rows] = await this._connection.execute(sql, params);
    return rows;
  }

  async insert(table, data) {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const placeholders = columns.map(() => '?').join(', ');
    const columnNames = columns.join(', ');
    const sql = `INSERT INTO ${table} (${columnNames}) VALUES (${placeholders})`;
    const [result] = await this.query(sql, values);
    return this.find(table, result.insertId);
  }

  async update(table, id, data) {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const setClause = columns.map(col => `${col} = ?`).join(', ');
    const sql = `UPDATE ${table} SET ${setClause} WHERE id = ?`;
    await this.query(sql, [...values, id]);
    return this.find(table, id);
  }

  async delete(table, id) {
    const sql = `DELETE FROM ${table} WHERE id = ?`;
    await this.query(sql, [id]);
  }

  async find(table, id) {
    const sql = `SELECT * FROM ${table} WHERE id = ?`;
    const rows = await this.query(sql, [id]);
    return rows[0] || null;
  }

  async findAll(table) {
    const sql = `SELECT * FROM ${table}`;
    return this.query(sql);
  }

  async close() {
    if (this._connection) {
      await this._connection.end();
      this._connection = null;
    }
  }
}

module.exports = { MySQLAdapter };
