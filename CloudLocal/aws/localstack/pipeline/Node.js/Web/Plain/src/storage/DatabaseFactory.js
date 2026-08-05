const { DynamoDBAdapter } = require('./Adapters/DynamoDB');
const { PostgreSQLAdapter } = require('./Adapters/PostgreSQL');
const { MySQLAdapter } = require('./Adapters/MySQL');
const { SQLiteAdapter } = require('./Adapters/SQLite');
const { SQLServerAdapter } = require('./Adapters/SQLServer');
const { MongoDBAdapter } = require('./Adapters/MongoDB');

function createDatabaseAdapter() {
  const driver = process.env.DB_DRIVER || 'postgresql';
  switch (driver) {
    case 'dynamodb':
      return new DynamoDBAdapter();
    case 'postgresql':
      return new PostgreSQLAdapter();
    case 'mysql':
      return new MySQLAdapter();
    case 'sqlite':
      return new SQLiteAdapter();
    case 'sqlserver':
      return new SQLServerAdapter();
    case 'mongodb':
      return new MongoDBAdapter();
    default:
      throw new Error(`Unsupported database driver: ${driver}`);
  }
}

module.exports = { createDatabaseAdapter };
