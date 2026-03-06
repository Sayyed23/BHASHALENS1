# DynamoDB Module - Three Tables
# BhashaLens AWS Infrastructure

# ─────────────────────────────────────────────
# Translation History Table
# ─────────────────────────────────────────────

resource "aws_dynamodb_table" "translation_history" {
  name         = "${var.project_name}-translation-history"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "timestamp"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "languagePair"
    type = "S"
  }

  # GSI for language pair analytics
  global_secondary_index {
    name            = "LanguagePairIndex"
    hash_key        = "languagePair"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # KMS encryption with customer-managed key
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  # Point-in-time recovery (35 days)
  point_in_time_recovery {
    enabled = true
  }

  # TTL for automatic deletion after 365 days
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  deletion_protection_enabled = var.environment == "prod" ? true : false

  tags = {
    Name = "${var.project_name}-translation-history"
  }
}

# ─────────────────────────────────────────────
# Saved Translations Table
# ─────────────────────────────────────────────

resource "aws_dynamodb_table" "saved_translations" {
  name         = "${var.project_name}-saved-translations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "translationId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "translationId"
    type = "S"
  }

  # KMS encryption with customer-managed key
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  # Point-in-time recovery (35 days)
  point_in_time_recovery {
    enabled = true
  }

  deletion_protection_enabled = var.environment == "prod" ? true : false

  tags = {
    Name = "${var.project_name}-saved-translations"
  }
}

# ─────────────────────────────────────────────
# User Preferences Table
# ─────────────────────────────────────────────

resource "aws_dynamodb_table" "user_preferences" {
  name         = "${var.project_name}-user-preferences"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  # KMS encryption with customer-managed key
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  # Point-in-time recovery (35 days)
  point_in_time_recovery {
    enabled = true
  }

  deletion_protection_enabled = var.environment == "prod" ? true : false

  tags = {
    Name = "${var.project_name}-user-preferences"
  }
}
