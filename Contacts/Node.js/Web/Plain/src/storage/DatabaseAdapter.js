class DatabaseAdapter {
  async connect() { throw new Error('Not implemented'); }
  async init(table, columns) { throw new Error('Not implemented'); }
  async getAll(table, options = {}) { throw new Error('Not implemented'); }
  async getById(table, id) { throw new Error('Not implemented'); }
  async create(table, data) { throw new Error('Not implemented'); }
  async update(table, id, data) { throw new Error('Not implemented'); }
  async delete(table, id) { throw new Error('Not implemented'); }
  async clear(table) { throw new Error('Not implemented'); }
  async search(table, field, query) { throw new Error('Not implemented'); }
  async close() { throw new Error('Not implemented'); }
}
module.exports = DatabaseAdapter;
