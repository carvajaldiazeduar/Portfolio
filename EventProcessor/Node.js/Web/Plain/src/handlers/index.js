async function processImage(jobData, job) {
  const { imageUrl, operations = ['resize', 'optimize'] } = jobData;
  console.log(`Processing image: ${imageUrl}`);
  console.log(`Operations: ${operations.join(', ')}`);
  
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  const result = {
    originalUrl: imageUrl,
    processedUrl: imageUrl.replace(/\.(jpg|jpeg|png|webp)$/i, '_processed.$1'),
    operations,
    completedAt: new Date().toISOString(),
  };
  
  console.log(`Image processed: ${result.processedUrl}`);
  return result;
}

async function sendBulkEmail(jobData, job) {
  const { recipients, subject, template, variables } = jobData;
  console.log(`Sending bulk email to ${recipients.length} recipients`);
  console.log(`Subject: ${subject}`);
  
  const batchSize = 50;
  const results = [];
  
  for (let i = 0; i < recipients.length; i += batchSize) {
    const batch = recipients.slice(i, i + batchSize);
    await new Promise(resolve => setTimeout(resolve, 200));
    
    const batchResult = batch.map(email => ({
      email,
      status: 'sent',
      messageId: `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    }));
    results.push(...batchResult);
    
    if (job && job.updateProgress) {
      await job.updateProgress(Math.round(((i + batch.length) / recipients.length) * 100));
    }
  }
  
  console.log(`Bulk email completed: ${results.length} sent`);
  return { sent: results.length, results };
}

async function generatePDFReport(jobData, job) {
  const { reportType, data, template } = jobData;
  console.log(`Generating PDF report: ${reportType}`);
  
  await new Promise(resolve => setTimeout(resolve, 1500));
  
  const result = {
    reportType,
    fileName: `${reportType}_${Date.now()}.pdf`,
    fileSize: Math.floor(Math.random() * 500000) + 100000,
    generatedAt: new Date().toISOString(),
    downloadUrl: `/reports/${reportType}_${Date.now()}.pdf`,
  };
  
  console.log(`PDF report generated: ${result.fileName}`);
  return result;
}

const HANDLERS = {
  'image.process': processImage,
  'email.bulk': sendBulkEmail,
  'report.generate': generatePDFReport,
};

function getHandler(taskType) {
  return HANDLERS[taskType];
}

function registerHandler(taskType, handler) {
  HANDLERS[taskType] = handler;
}

module.exports = { getHandler, registerHandler, HANDLERS };