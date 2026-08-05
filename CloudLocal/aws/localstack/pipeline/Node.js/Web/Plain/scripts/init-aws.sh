#!/bin/bash
set -e

echo "Initializing AWS resources in LocalStack..."

ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-mock_key}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-mock_secret}"
AWS_REGION="${AWS_REGION:-us-east-1}"

export AWS_ENDPOINT_URL="${ENDPOINT_URL}"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${AWS_REGION}"

aws --endpoint-url "${ENDPOINT_URL}" s3 mb s3://pipeline-uploads-bucket 2>/dev/null || echo "Bucket already exists or creation skipped"

aws --endpoint-url "${ENDPOINT_URL}" dynamodb create-table \
  --table-name pipeline-files-metadata \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  2>/dev/null || echo "Table already exists or creation skipped"

aws --endpoint-url "${ENDPOINT_URL}" sqs create-queue \
  --queue-name pipeline-file-processing \
  2>/dev/null || echo "Queue already exists or creation skipped"

aws --endpoint-url "${ENDPOINT_URL}" sqs create-queue \
  --queue-name pipeline-file-processing-dlq \
  2>/dev/null || echo "DLQ already exists or creation skipped"

aws --endpoint-url "${ENDPOINT_URL}" sns create-topic \
  --name pipeline-file-events \
  2>/dev/null || echo "Topic already exists or creation skipped"

aws --endpoint-url "${ENDPOINT_URL}" sqs set-queue-attributes \
  --queue-url http://localhost:4566/000000000000/pipeline-file-processing \
  --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:pipeline-file-processing-dlq\",\"maxReceiveCount\":\"3\"}"}' \
  2>/dev/null || echo "Queue attributes may already be set"

aws --endpoint-url "${ENDPOINT_URL}" cloudwatch put-metric-data \
  --namespace Pipeline \
  --metric-data MetricName=PipelineInitialized,Value=1,Unit=Count \
  2>/dev/null || echo "CloudWatch metric may have failed"

echo "AWS resources initialization complete!"