# Security Module Variables

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs for IAM policies"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs for IAM policies"
  type        = list(string)
  default     = []
}

variable "bedrock_model_ids" {
  description = "Bedrock model IDs for IAM policy"
  type = object({
    claude_sonnet = string
    titan_text    = string
  })
}
