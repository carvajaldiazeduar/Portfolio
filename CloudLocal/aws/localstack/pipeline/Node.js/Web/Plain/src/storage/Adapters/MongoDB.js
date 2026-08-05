const { MongoClient } = require('mongodb');
const DatabaseAdapter = require('../DatabaseAdapter');

class MongoDBAdapter extends DatabaseAdapter {
  constructor() {
    super();
    this._client = null;
    this._db = null;
  }

  async connect() {
    const uri = process.env.DB_URI || 'mongodb://admin:admin@localhost:27017';
    this._client = new MongoClient(uri);
    await this._client.connect();
    this._db = this._client.db(process.env.DB_NAME || 'pipeline_db');
    console.log('Connected to MongoDB');
  }

  async query(collectionName, filter) {
    if (!this._db) await this.connect();
    return this._db.collection(collectionName).find(filter || {}).toArray();
  }

  async insert(table, data) {
    if (!this._db) await this.connect();
    const result = await this._db.collection(table).insertOne(data);
    return this.find(table, result.insertedId);
  }

  async update(table, id, data) {
    if (!this._db) await this.connect();
    const { ObjectId } = require('mongodb');
    await this._db.collection(table).updateOne(
      { _id: new ObjectId(id) },
      { $set: data }
    );
    return this.find(table, id);
  }

  async delete(table, id) {
    if (!this._db) await this.connect();
    const { ObjectId } = require('mongodb');
    await this._db.collection(table).deleteOne({ _id: new ObjectId(id) });
  }

  async find(table, id) {
    if (!this._db) await this.connect();
    const { ObjectId } = require('mongodb');
    const doc = await this._db.collection(table).findOne({ _id: new ObjectId(id) });
    return doc || null;
  }

  async findAll(table) {
    if (!this._db) await this.connect();
    return this._db.collection(table).find({}).toArray();
  }

  async close() {
    if (this._client) {
      await this._client.close();
      this._client = null;
      this._db = null;
    }
  }
}

module.exports = { MongoDBAdapter };
