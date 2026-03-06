variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_gateway_stage_name" {
  description = "Name of the API Gateway Stage"
  type        = string
}

variable "lambda_function_names" {
  description = "List of Lambda function names to monitor"
  type        = list(string)
}

variable "dynamodb_table_names" {
  description = "List of DynamoDB table names to monitor"
  type        = list(string)
}

variable "bedrock_model_ids" {
  description = "List of Bedrock model IDs to monitor"
  type        = list(string)
  default     = ["anthropic.claude-3-sonnet-20240229-v1:0", "amazon.titan-text-express-v1"]
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

variable "budget_limit_amount" {
  description = "Monthly budget limit amount in USD"
  type        = number
  default     = 300
}

variable "budget_warning_threshold" {
  description = "Percentage of budget limit to trigger a warning"
  type        = number
  default     = 66 # ~200 USD out of 300
}
