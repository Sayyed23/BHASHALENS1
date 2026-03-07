variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository URL (e.g., https://github.com/username/repo)"
  type        = string
  default     = "" # Replace with actual repository or configure manually
}

variable "github_token" {
  description = "GitHub personal access token for Amplify to access the repository"
  type        = string
  sensitive   = true
  default     = ""
}

variable "api_gateway_url" {
  description = "URL of the deployed API Gateway"
  type        = string
}

variable "enable_custom_domain" {
  description = "Whether to configure a custom domain"
  type        = bool
  default     = false
}

variable "custom_domain_name" {
  description = "Custom domain name (if enable_custom_domain is true)"
  type        = string
  default     = ""
}
