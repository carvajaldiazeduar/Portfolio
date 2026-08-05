const { DynamoDBClient, PutItemCommand, GetItemCommand, UpdateItemCommand, DeleteItemCommand, QueryCommand, ScanCommand } = require('@aws-sdk/client-dynamodb');
const { marshall, unmarshall } = require('@aws-sdk/util-dynamodb');
const DatabaseAdapter = require('../DatabaseAdapter');

class DynamoDBAdapter extends DatabaseAdapter {
  constructor() {
    super();
    this._client = null;
    this._connected = false;
  }

  _getClient() {
    if (!this._client) {
      this._client = new DynamoDBClient({
        region: process.env.AWS_REGION || 'us-east-1',
        endpoint: process.env.AWS_ENDPOINT_URL || 'http://localhost:4566',
        credentials: {
          accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'mock_key',
          secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'mock_secret',
        },
      });
    }
    return this._client;
  }

  async connect() {
    const client = this._getClient();
    await client.config.region();
    this._connected = true;
    console.log('Connected to DynamoDB');
  }

  async insert(table, data) {
    const client = this._getClient();
    const params = {
      TableName: table,
      Item: marshall(data),
    };
    await client.send(new PutItemCommand(params));
    return data;
  }

  async find(table, id) {
    const client = this._getClient();
    const key = marshall({ id });
    const result = await client.send(new GetItemCommand({
      TableName: table,
      Key: key,
    }));
    return result.Item ? unmarshall(result.Item) : null;
  }

  async findAll(table) {
    const client = this._getClient();
    const result = await client.send(new ScanCommand({ TableName: table }));
    return result.Items.map(item => unmarshall(item));
  }

  async update(table, id, data) {
    const client = this._getClient();
    const updateExpressions = [];
    const expressionAttributeValues = {};
    const expressionAttributeNames = {};

    Object.keys(data).forEach((key, index) => {
      const attrName = `#attr${index}`;
      const attrValue = `:val${index}`;
      updateExpressions.push(`${attrName} = ${attrValue}`);
      expressionAttributeNames[attrName] = key;
      expressionAttributeValues[attrValue] = marshall(data[key]);
    });

    await client.send(new UpdateItemCommand({
      TableName: table,
      Key: marshall({ id }),
      UpdateExpression: `SET ${updateExpressions.join(', ')}`,
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
      ReturnValues: 'ALL_NEW',
    }));

    return this.find(table, id);
  }

  async delete(table, id) {
    const client = this._getClient();
    await client.send(new DeleteItemCommand({
      TableName: table,
      Key: marshall({ id }),
    }));
  }

  async query(table, keyCondition, expressionValues) {
    const client = this._getClient();
    const result = await client.send(new QueryCommand({
      TableName: table,
      KeyConditionExpression: keyCondition,
      ExpressionAttributeValues: expressionValues
        ? marshall(expressionValues)
        : undefined,
    }));
    return result.Items.map(item => unmarshall(item));
  }

  async close() {
    if (this._client) {
      this._client.destroy();
      this._client = null;
      this._connected = false;
    }
  }
}

module.exports = { DynamoDBAdapter };
