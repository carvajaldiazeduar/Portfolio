variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_endpoint_url" {
  description = "AWS endpoint URL (LocalStack)"
  type        = string
  default     = "http://localhost:4566"
}

variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
  default     = "mock_key"
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
  default     = "mock_secret"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "bucket_name" {
  description = "S3 bucket name for file uploads"
  type        = string
  default     = "pipeline-uploads-bucket"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for file metadata"
  type        = string
  default     = "pipeline-files-metadata"
}

variable "sqs_queue_name" {
  description = "SQS queue name for file processing"
  type        = string
  default     = "pipeline-file-processing"
}

variable "sns_topic_name" {
  description = "SNS topic name for file events"
  type        = string
  default     = "pipeline-file-events"
}

variable "file_retention_days" {
  description = "Number of days to retain files in S3"
  type        = number
  default     = 30
}

variable "cloudwatch_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}
