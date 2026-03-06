# DynamoDB Module Variables

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption"
  type        = string
}
