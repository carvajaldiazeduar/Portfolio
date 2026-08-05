class DatabaseAdapter {
  async connect() { throw new Error('Not implemented'); }
  async query(sql, params) { throw new Error('Not implemented'); }
  async insert(table, data) { throw new Error('Not implemented'); }
  async update(table, id, data) { throw new Error('Not implemented'); }
  async delete(table, id) { throw new Error('Not implemented'); }
  async find(table, id) { throw new Error('Not implemented'); }
  async findAll(table) { throw new Error('Not implemented'); }
  async close() { throw new Error('Not implemented'); }
}

module.exports = DatabaseAdapter;
