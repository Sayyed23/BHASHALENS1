# DynamoDB Module Outputs

output "translation_history_table_name" {
  description = "Name of the Translation History table"
  value       = aws_dynamodb_table.translation_history.name
}

output "translation_history_table_arn" {
  description = "ARN of the Translation History table"
  value       = aws_dynamodb_table.translation_history.arn
}

output "saved_translations_table_name" {
  description = "Name of the Saved Translations table"
  value       = aws_dynamodb_table.saved_translations.name
}

output "saved_translations_table_arn" {
  description = "ARN of the Saved Translations table"
  value       = aws_dynamodb_table.saved_translations.arn
}

output "user_preferences_table_name" {
  description = "Name of the User Preferences table"
  value       = aws_dynamodb_table.user_preferences.name
}

output "user_preferences_table_arn" {
  description = "ARN of the User Preferences table"
  value       = aws_dynamodb_table.user_preferences.arn
}

output "all_table_arns" {
  description = "List of all DynamoDB table ARNs"
  value = [
    aws_dynamodb_table.translation_history.arn,
    aws_dynamodb_table.saved_translations.arn,
    aws_dynamodb_table.user_preferences.arn
  ]
}
