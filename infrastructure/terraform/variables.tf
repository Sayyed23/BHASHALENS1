# Variables for BhashaLens AWS Infrastructure

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "bhashalens"
}

variable "firebase_project_id" {
  description = "Firebase project ID for token validation"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.11"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "bedrock_model_ids" {
  description = "Amazon Bedrock model IDs"
  type = object({
    claude_sonnet    = string
    claude_sonnet_4  = string
    titan_text       = string
    titan_embeddings = string
  })
  default = {
    claude_sonnet    = "anthropic.claude-3-sonnet-20240229-v1:0"
    claude_sonnet_4  = "apac.anthropic.claude-sonnet-4-20250514-v1:0"
    titan_text       = "amazon.titan-text-express-v1"
    titan_embeddings = "amazon.titan-embed-text-v2:0"
  }
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle steady-state rate (req/sec)"
  type        = number
  default     = 500
}

variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 1000
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "cors_allowed_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.cors_allowed_origins) > 0
    error_message = "cors_allowed_origins must be explicitly configured."
  }
}
variable "github_repository" {
  description = "GitHub repository URL for Amplify"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub personal access token for Amplify"
  type        = string
  default     = ""
  sensitive   = true
}
