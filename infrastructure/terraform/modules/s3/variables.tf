# S3 Module Variables

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
}

variable "account_id" {
  description = "AWS account ID for bucket naming"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption"
  type        = string
}
variable "cors_allowed_origins" {
  description = "Allowed origins for CORS on export bucket"
  type        = list(string)

  validation {
    condition     = !contains(var.cors_allowed_origins, "*")
    error_message = "CORS allowed origins must not contain wildcard '*'. Specify explicit origins."
  }
}  