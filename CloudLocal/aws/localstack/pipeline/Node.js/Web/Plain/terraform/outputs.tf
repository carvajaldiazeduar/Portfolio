output "s3_bucket_name" {
  description = "Name of the S3 bucket for file uploads"
  value       = aws_s3_bucket.uploads.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.uploads.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for file metadata"
  value       = aws_dynamodb_table.files_metadata.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.files_metadata.arn
}

output "sqs_queue_url" {
  description = "URL of the SQS queue for file processing"
  value       = aws_sqs_queue.file_processing.id
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.file_processing.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for file events"
  value       = aws_sns_topic.file_events.arn
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.pipeline_logs.name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  value       = var.aws_endpoint_url
}
