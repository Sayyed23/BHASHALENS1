# DynamoDB Tables for BhashaLens

# User Preferences Table
resource "aws_dynamodb_table" "user_preferences" {
  name           = "${var.project_name}-user-preferences"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "user_id"
  
  attribute {
    name = "user_id"
    type = "S"
  }
  
  # Enable encryption at rest with AWS managed keys
  server_side_encryption {
    enabled = true
  }
  
  # Enable point-in-time recovery for production
  point_in_time_recovery {
    enabled = true
  }
  
  # Enable deletion protection for production
  deletion_protection_enabled = var.environment == "production" ? true : false
  
  tags = {
    Name = "${var.project_name}-user-preferences"
  }
}

# Translation History Table
resource "aws_dynamodb_table" "translation_history" {
  name           = "${var.project_name}-translation-history"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "user_id"
  range_key      = "timestamp"
  
  attribute {
    name = "user_id"
    type = "S"
  }
  
  attribute {
    name = "timestamp"
    type = "N"
  }
  
  attribute {
    name = "source_lang"
    type = "S"
  }
  
  attribute {
    name = "target_lang"
    type = "S"
  }
  
  # Global Secondary Index for querying by language pair
  global_secondary_index {
    name            = "LanguagePairIndex"
    hash_key        = "source_lang"
    range_key       = "target_lang"
    projection_type = "ALL"
  }
  
  # Enable encryption at rest with AWS managed keys
  server_side_encryption {
    enabled = true
  }
  
  # Enable point-in-time recovery for production
  point_in_time_recovery {
    enabled = true
  }
  
  # Enable deletion protection for production
  deletion_protection_enabled = var.environment == "production" ? true : false
  
  # TTL for automatic data expiration (optional)
  ttl {
    attribute_name = "expiration_time"
    enabled        = true
  }
  
  tags = {
    Name = "${var.project_name}-translation-history"
  }
}

# Language Pack Metadata Table
resource "aws_dynamodb_table" "language_pack_metadata" {
  name           = "${var.project_name}-language-pack-metadata"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "pack_id"
  
  attribute {
    name = "pack_id"
    type = "S"
  }
  
  attribute {
    name = "version"
    type = "S"
  }
  
  # Global Secondary Index for querying by version
  global_secondary_index {
    name            = "VersionIndex"
    hash_key        = "version"
    projection_type = "ALL"
  }
  
  # Enable encryption at rest with AWS managed keys
  server_side_encryption {
    enabled = true
  }
  
  # Enable point-in-time recovery for production
  point_in_time_recovery {
    enabled = true
  }
  
  # Enable deletion protection for production
  deletion_protection_enabled = var.environment == "production" ? true : false
  
  tags = {
    Name = "${var.project_name}-language-pack-metadata"
  }
}

# Outputs
output "user_preferences_table_name" {
  description = "Name of the user preferences DynamoDB table"
  value       = aws_dynamodb_table.user_preferences.name
}

output "user_preferences_table_arn" {
  description = "ARN of the user preferences DynamoDB table"
  value       = aws_dynamodb_table.user_preferences.arn
}

output "translation_history_table_name" {
  description = "Name of the translation history DynamoDB table"
  value       = aws_dynamodb_table.translation_history.name
}

output "translation_history_table_arn" {
  description = "ARN of the translation history DynamoDB table"
  value       = aws_dynamodb_table.translation_history.arn
}

output "language_pack_metadata_table_name" {
  description = "Name of the language pack metadata DynamoDB table"
  value       = aws_dynamodb_table.language_pack_metadata.name
}

output "language_pack_metadata_table_arn" {
  description = "ARN of the language pack metadata DynamoDB table"
  value       = aws_dynamodb_table.language_pack_metadata.arn
}
