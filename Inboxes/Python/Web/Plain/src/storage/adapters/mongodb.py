import os
import re
from bson.objectid import ObjectId
from pymongo import MongoClient
from storage.database_adapter import DatabaseAdapter

class MongoDB(DatabaseAdapter):
    def __init__(self):
        self.db = None
        self.connect()

    def connect(self):
        if self.db:
            return
        client = MongoClient(
            host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", "27017")),
        )
        self.db = client[os.getenv("DB_NAME", "inboxes")]

    def _serialize(self, doc):
        if doc and "_id" in doc:
            doc["id"] = str(doc.pop("_id"))
        return doc

    def init_table(self, table, columns=None):
        self.connect()
        if table not in self.db.list_collection_names():
            self.db.create_collection(table)

    def get_all(self, table):
        self.connect()
        return [self._serialize(doc) for doc in self.db[table].find({}).sort("_id", 1)]

    def get_by_id(self, table, id):
        self.connect()
        doc = self.db[table].find_one({"_id": ObjectId(id)})
        return self._serialize(doc)

    def create(self, table, data):
        self.connect()
        result = self.db[table].insert_one(data)
        doc = self.db[table].find_one({"_id": result.inserted_id})
        return self._serialize(doc)

    def update(self, table, id, data):
        self.connect()
        result = self.db[table].update_one(
            {"_id": ObjectId(id)}, {"$set": data}
        )
        return result.modified_count > 0

    def delete(self, table, id):
        self.connect()
        result = self.db[table].delete_one({"_id": ObjectId(id)})
        return result.deleted_count > 0

    def search(self, table, field, query):
        self.connect()
        pattern = re.compile(re.escape(query), re.IGNORECASE)
        return [
            self._serialize(doc)
            for doc in self.db[table].find({field: {"$regex": pattern}}).sort("_id", 1)
        ]

    def close(self):
        if self.db:
            self.db.client.close()
