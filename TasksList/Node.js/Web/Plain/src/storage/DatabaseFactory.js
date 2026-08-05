const PostgreSQLAdapter = require('./adapters/PostgreSQL');
const MySQLAdapter = require('./adapters/MySQL');
const SQLiteAdapter = require('./adapters/SQLite');
const SQLServerAdapter = require('./adapters/SQLServer');
const MongoDBAdapter = require('./adapters/MongoDB');

function createAdapter(defaultDB) {
  const driver = process.env.DB_DRIVER || 'pgsql';
  switch (driver) {
    case 'sqlite':
      return new SQLiteAdapter(defaultDB);
    case 'mysql':
      return new MySQLAdapter(defaultDB);
    case 'mongodb':
      return new MongoDBAdapter(defaultDB);
    case 'sqlserver':
    case 'mssql':
      return new SQLServerAdapter(defaultDB);
    case 'pgsql':
    default:
      return new PostgreSQLAdapter(defaultDB);
  }
}

module.exports = { createAdapter };
