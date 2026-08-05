const { createDatabaseAdapter } = require('../storage/DatabaseFactory');
const { createCache } = require('../cache/CacheFactory');
const { getHandler } = require('../handlers');
const { FileProcessor } = require('./FileProcessor');

class PipelineService {
  constructor() {
    this._db = createDatabaseAdapter();
    this._cache = createCache();
    this._processor = new FileProcessor();
    this._queue = null;
  }

  async initialize(queue) {
    await this._db.connect();
    this._queue = queue;
    console.log('PipelineService initialized');
  }

  async ingestFile(fileData) {
    const { fileName, fileType, fileSize, buffer } = fileData;

    const uploadResult = await this._executeHandler('file.upload', {
      fileName,
      fileType,
      fileSize,
      bucket: 'pipeline-uploads',
    });

    const processResult = await this._executeHandler('file.process', {
      key: uploadResult.key,
      fileName,
      fileType,
      fileSize,
    });

    const metadataResult = await this._executeHandler('metadata.save', {
      key: uploadResult.key,
      fileName,
      fileType,
      fileSize,
      extractedData: processResult.extractedData,
      status: 'completed',
    });

    await this._executeHandler('notification.send', {
      key: uploadResult.key,
      fileName,
      status: 'completed',
    });

    await this._executeHandler('metrics.record', {
      key: uploadResult.key,
      fileType,
      processingTime: processResult.processingTime,
    });

    return {
      upload: uploadResult,
      processing: processResult,
      metadata: metadataResult,
    };
  }

  async _executeHandler(taskType, data) {
    const handler = getHandler(taskType);
    if (!handler) {
      throw new Error(`No handler registered for task type: ${taskType}`);
    }
    return handler(data, null);
  }

  async getFileMetadata(key) {
    const cached = await this._cache.get(`metadata:${key}`);
    if (cached) return cached;

    const metadata = await this._db.find('files', key);
    if (metadata) {
      await this._cache.set(`metadata:${key}`, metadata, 300);
    }
    return metadata;
  }

  async listFiles() {
    return this._db.findAll('files');
  }

  async getMetrics() {
    const metrics = await this._db.findAll('metrics');
    return metrics;
  }

  async close() {
    await this._db.close();
  }
}

module.exports = { PipelineService };
