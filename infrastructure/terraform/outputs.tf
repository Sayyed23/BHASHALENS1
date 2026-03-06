# Outputs for BhashaLens AWS Infrastructure

# DynamoDB
output "translation_history_table_name" {
  description = "Name of the translation history DynamoDB table"
  value       = module.dynamodb.translation_history_table_name
}

output "saved_translations_table_name" {
  description = "Name of the saved translations DynamoDB table"
  value       = module.dynamodb.saved_translations_table_name
}

output "user_preferences_table_name" {
  description = "Name of the user preferences DynamoDB table"
  value       = module.dynamodb.user_preferences_table_name
}

# S3
output "static_assets_bucket_name" {
  description = "Name of the static assets S3 bucket"
  value       = module.s3.static_assets_bucket_name
}

output "translation_exports_bucket_name" {
  description = "Name of the translation exports S3 bucket"
  value       = module.s3.translation_exports_bucket_name
}

# KMS
output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = module.security.kms_key_arn
}

# Amplify
output "amplify_app_id" {
  description = "ID of the Amplify App"
  value       = module.amplify.amplify_app_id
}

output "amplify_default_domain" {
  description = "Default domain for the Amplify App"
  value       = module.amplify.amplify_default_domain
}

output "amplify_branch_url" {
  description = "URL of the deployed branch"
  value       = module.amplify.amplify_branch_url
}

# Monitoring
output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = module.monitoring.dashboard_arn
}

output "sns_alerts_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.monitoring.sns_alerts_topic_arn
}
