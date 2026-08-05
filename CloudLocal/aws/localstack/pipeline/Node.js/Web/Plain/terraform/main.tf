terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = var.aws_access_key_id
  secret_key                  = var.aws_secret_access_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3  = var.aws_endpoint_url
    dynamodb = var.aws_endpoint_url
    sqs  = var.aws_endpoint_url
    sns  = var.aws_endpoint_url
    cloudwatch = var.aws_endpoint_url
    lambda = var.aws_endpoint_url
  }
}

resource "aws_s3_bucket" "uploads" {
  bucket = var.bucket_name
  tags = {
    Name        = "pipeline-uploads"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "uploads_lifecycle" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "expire-old-files"
    status = "Enabled"

    expiration {
      days = var.file_retention_days
    }
  }
}

resource "aws_dynamodb_table" "files_metadata" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "fileName"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  global_secondary_index {
    name               = "status-index"
    hash_key           = "status"
    projection_type    = "ALL"
  }

  tags = {
    Name        = "pipeline-files-metadata"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_sqs_queue" "file_processing" {
  name = var.sqs_queue_name

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.file_processing_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "pipeline-file-processing"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_sqs_queue" "file_processing_dlq" {
  name = "${var.sqs_queue_name}-dlq"

  tags = {
    Name        = "pipeline-file-processing-dlq"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_sns_topic" "file_events" {
  name = var.sns_topic_name

  tags = {
    Name        = "pipeline-file-events"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn = aws_sns_topic.file_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.file_processing.arn
}

resource "aws_cloudwatch_log_group" "pipeline_logs" {
  name              = "/aws/lambda/pipeline-worker"
  retention_in_days = var.cloudwatch_retention_days

  tags = {
    Name        = "pipeline-worker-logs"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "processing_errors" {
  alarm_name          = "pipeline-processing-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ProcessingErrors"
  namespace           = "Pipeline"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Triggers when more than 5 processing errors occur in 5 minutes"
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "pipeline-processing-errors"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "pipeline-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "pipeline-lambda-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "pipeline-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.uploads.arn,
          "${aws_s3_bucket.uploads.arn}/*",
        ]
      },
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan",
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.files_metadata.arn
      },
      {
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.file_processing.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
