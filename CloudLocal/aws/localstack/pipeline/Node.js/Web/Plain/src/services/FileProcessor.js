class FileProcessor {
  constructor() {
    this._supportedTypes = ['pdf', 'csv', 'image'];
  }

  getSupportedTypes() {
    return this._supportedTypes;
  }

  async process(fileBuffer, fileType, fileName) {
    if (!this._supportedTypes.includes(fileType)) {
      throw new Error(`Unsupported file type: ${fileType}`);
    }

    const startTime = Date.now();

    let result;
    switch (fileType) {
      case 'csv':
        result = this._processCSV(fileBuffer, fileName);
        break;
      case 'pdf':
        result = this._processPDF(fileBuffer, fileName);
        break;
      case 'image':
        result = this._processImage(fileBuffer, fileName);
        break;
      default:
        result = { content: 'Unknown file type' };
    }

    const processingTime = Date.now() - startTime;

    return {
      fileName,
      fileType,
      fileSize: fileBuffer.length,
      result,
      processingTime,
      processedAt: new Date().toISOString(),
    };
  }

  _processCSV(buffer, fileName) {
    const content = buffer.toString('utf-8');
    const lines = content.split('\n').filter(line => line.trim());
    const headers = lines[0] ? lines[0].split(',') : [];
    const rowCount = lines.length - 1;

    return {
      fileName,
      format: 'csv',
      headers,
      rowCount,
      preview: lines.slice(0, 5).join('\n'),
    };
  }

  _processPDF(buffer, fileName) {
    return {
      fileName,
      format: 'pdf',
      size: buffer.length,
      pageCount: Math.floor(buffer.length / 1000) + 1,
      extractedText: `Extracted text from ${fileName}`,
    };
  }

  _processImage(buffer, fileName) {
    return {
      fileName,
      format: 'image',
      size: buffer.length,
      dimensions: { width: 1920, height: 1080 },
      thumbnailGenerated: true,
    };
  }
}

module.exports = { FileProcessor };
