variable "env" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

variable "lambda_execution_role_arn" {
  type        = string
  description = "ARN of the IAM role for Lambda execution"
}

variable "translation_history_table" {
  type        = string
  description = "Name of the DynamoDB table for translation history"
}

variable "saved_translations_table" {
  type        = string
  description = "Name of the DynamoDB table for saved translations"
}

variable "user_preferences_table" {
  type        = string
  description = "Name of the DynamoDB table for user preferences"
}

variable "export_bucket" {
  type        = string
  description = "Name of the S3 bucket for exports"
}

variable "bedrock_model_id" {
  type        = string
  description = "Bedrock model ID for translations"
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "gemini_api_key_arn" {
  type        = string
  description = "ARN of Secrets Manager secret with Gemini API key (optional)"
  default     = ""
}
