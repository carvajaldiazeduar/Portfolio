async function uploadFile(jobData, job) {
  const { fileName, fileType, fileSize, bucket = 'pipeline-uploads' } = jobData;
  console.log(`Processing file upload: ${fileName} (${fileType}, ${fileSize} bytes)`);

  await new Promise(resolve => setTimeout(resolve, 500));

  const result = {
    fileName,
    fileType,
    fileSize,
    bucket,
    key: `${bucket}/${Date.now()}_${fileName}`,
    status: 'uploaded',
    uploadedAt: new Date().toISOString(),
  };

  console.log(`File uploaded: ${result.key}`);
  return result;
}

async function processFile(jobData, job) {
  const { key, fileType, fileName } = jobData;
  console.log(`Processing file: ${key}`);

  await new Promise(resolve => setTimeout(resolve, 1000));

  let extractedData = {};
  if (fileType === 'csv') {
    extractedData = { rows: Math.floor(Math.random() * 1000) + 1, columns: ['id', 'name', 'value'] };
  } else if (fileType === 'pdf') {
    extractedData = { pageCount: Math.floor(Math.random() * 50) + 1, wordCount: Math.floor(Math.random() * 5000) + 100 };
  } else if (fileType === 'image') {
    extractedData = { width: 1920, height: 1080, format: 'png' };
  } else {
    extractedData = { content: 'Processed file content' };
  }

  const result = {
    key,
    fileName,
    fileType,
    extractedData,
    status: 'processed',
    processedAt: new Date().toISOString(),
  };

  console.log(`File processed: ${key}`);
  return result;
}

async function saveMetadata(jobData, job) {
  const { key, fileName, fileType, fileSize, extractedData, status } = jobData;
  console.log(`Saving metadata for: ${key}`);

  await new Promise(resolve => setTimeout(resolve, 300));

  const result = {
    id: key,
    fileName,
    fileType,
    fileSize,
    extractedData,
    status,
    createdAt: new Date().toISOString(),
  };

  console.log(`Metadata saved for: ${key}`);
  return result;
}

async function sendNotification(jobData, job) {
  const { key, status, fileName } = jobData;
  console.log(`Sending notification for: ${key}`);

  await new Promise(resolve => setTimeout(resolve, 200));

  const result = {
    key,
    fileName,
    status,
    message: `File ${fileName} processing ${status}`,
    sentAt: new Date().toISOString(),
  };

  console.log(`Notification sent for: ${key}`);
  return result;
}

async function recordMetrics(jobData, job) {
  const { key, fileType, processingTime } = jobData;
  console.log(`Recording metrics for: ${key}`);

  await new Promise(resolve => setTimeout(resolve, 100));

  const result = {
    key,
    fileType,
    processingTime,
    recordedAt: new Date().toISOString(),
  };

  console.log(`Metrics recorded for: ${key}`);
  return result;
}

const HANDLERS = {
  'file.upload': uploadFile,
  'file.process': processFile,
  'metadata.save': saveMetadata,
  'notification.send': sendNotification,
  'metrics.record': recordMetrics,
};

function getHandler(taskType) {
  return HANDLERS[taskType];
}

function registerHandler(taskType, handler) {
  HANDLERS[taskType] = handler;
}

module.exports = { getHandler, registerHandler, HANDLERS };
