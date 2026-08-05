const { PipelineService } = require('../services/PipelineService');
const { FileProcessor } = require('../services/FileProcessor');
const { DynamoDBAdapter } = require('../storage/Adapters/DynamoDB');
const { LocalCache } = require('../cache/Adapters/Local');

describe('PipelineService', () => {
  let pipeline;
  let processor;

  beforeEach(() => {
    processor = new FileProcessor();
    pipeline = new PipelineService();
  });

  test('FileProcessor supports pdf, csv, and image types', () => {
    const types = processor.getSupportedTypes();
    expect(types).toContain('pdf');
    expect(types).toContain('csv');
    expect(types).toContain('image');
  });

  test('FileProcessor throws for unsupported file types', async () => {
    await expect(
      processor.process(Buffer.from('test'), 'exe', 'test.exe')
    ).rejects.toThrow('Unsupported file type: exe');
  });

  test('FileProcessor processes CSV files', async () => {
    const csvContent = 'id,name,value\n1,test,100\n2,example,200\n';
    const result = await processor.process(Buffer.from(csvContent), 'csv', 'data.csv');
    expect(result.fileType).toBe('csv');
    expect(result.result.rowCount).toBe(2);
    expect(result.result.headers).toEqual(['id', 'name', 'value']);
  });

  test('FileProcessor processes PDF files', async () => {
    const result = await processor.process(Buffer.from('pdf-content'), 'pdf', 'document.pdf');
    expect(result.fileType).toBe('pdf');
    expect(result.result.format).toBe('pdf');
  });

  test('FileProcessor processes image files', async () => {
    const result = await processor.process(Buffer.from('image-content'), 'image', 'photo.png');
    expect(result.fileType).toBe('image');
    expect(result.result.format).toBe('image');
  });

  test('DynamoDBAdapter can be instantiated', () => {
    const adapter = new DynamoDBAdapter();
    expect(adapter).toBeDefined();
  });

  test('LocalCache can be instantiated', () => {
    const cache = new LocalCache();
    expect(cache).toBeDefined();
  });

  test('LocalCache set and get', async () => {
    const cache = new LocalCache();
    await cache.set('test-key', { value: 'test' }, 60);
    const result = await cache.get('test-key');
    expect(result).toEqual({ value: 'test' });
  });

  test('LocalCache increment', async () => {
    const cache = new LocalCache();
    const val1 = await cache.increment('counter', 60);
    const val2 = await cache.increment('counter', 60);
    expect(val1).toBe(1);
    expect(val2).toBe(2);
  });

  test('LocalCache del removes key', async () => {
    const cache = new LocalCache();
    await cache.set('test-key', 'value', 60);
    await cache.del('test-key');
    const result = await cache.get('test-key');
    expect(result).toBeNull();
  });
});