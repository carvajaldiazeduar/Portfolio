const { MongoClient, ObjectId } = require('mongodb');
const DatabaseAdapter = require('../DatabaseAdapter');

class MongoDBAdapter extends DatabaseAdapter {
  constructor(defaultDB) {
    super();
    this.defaultDB = defaultDB || 'mongodb';
  }

  async connect() {
    const client = new MongoClient(`mongodb://${process.env.DB_HOST || 'localhost'}:${parseInt(process.env.DB_PORT || '27017')}`);
    await client.connect();
    this.client = client;
    this.db = client.db(process.env.DB_NAME || this.defaultDB);
  }

  async _nextSeq(table) {
    const r = await this.db.collection('counters').findOneAndUpdate(
      { _id: table },
      { $inc: { seq: 1 } },
      { returnDocument: 'after', upsert: true }
    );
    return r.seq;
  }

  _toRecord(doc) {
    if (!doc) return null;
    const { _id, ...rest } = doc;
    return { id: _id, ...rest };
  }

  async init(table, columns) {
    const collections = await this.db.listCollections({ name: table }).toArray();
    if (collections.length === 0) await this.db.createCollection(table);
    const counters = await this.db.listCollections({ name: 'counters' }).toArray();
    if (counters.length === 0) {
      await this.db.createCollection('counters');
      await this.db.collection('counters').insertOne({ _id: table, seq: 1 });
    }
  }

  async getAll(table, options = {}) {
    const coll = this.db.collection(table);
    let cursor = coll.find({});
    if (options.orderBy) {
      cursor = cursor.sort({ [options.orderBy]: options.orderDir === 'DESC' ? -1 : 1 });
    } else {
      cursor = cursor.sort({ _id: 1 });
    }
    if (options.limit) cursor = cursor.limit(options.limit);
    const docs = await cursor.toArray();
    return docs.map(d => this._toRecord(d));
  }

  async getById(table, id) {
    const doc = await this.db.collection(table).findOne({ _id: parseInt(id) });
    return this._toRecord(doc);
  }

  async create(table, data) {
    const _id = await this._nextSeq(table);
    const doc = { ...data, _id };
    await this.db.collection(table).insertOne(doc);
    return this._toRecord(doc);
  }

  async update(table, id, data) {
    await this.db.collection(table).updateOne({ _id: parseInt(id) }, { $set: data });
    return this.getById(table, id);
  }

  async delete(table, id) {
    const r = await this.db.collection(table).deleteOne({ _id: parseInt(id) });
    return { changes: r.deletedCount };
  }

  async clear(table) {
    const r = await this.db.collection(table).deleteMany({});
    return { changes: r.deletedCount };
  }

  async search(table, field, query) {
    const docs = await this.db.collection(table)
      .find({ [field]: { $regex: query.replace(/%/g, '.*'), $options: 'i' } })
      .sort({ _id: 1 })
      .toArray();
    return docs.map(d => this._toRecord(d));
  }

  async close() {
    await this.client.close();
  }
}
module.exports = MongoDBAdapter;
