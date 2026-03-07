# BhashaLens AWS Infrastructure - Root Configuration
# Phase 1: Core Infrastructure Setup

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "BhashaLens"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ─────────────────────────────────────────────
# DynamoDB Module 
# ─────────────────────────────────────────────

module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.kms_key_arn
}

# ─────────────────────────────────────────────
# S3 Module
# ─────────────────────────────────────────────

module "s3" {
  source = "./modules/s3"

  project_name         = var.project_name
  account_id           = data.aws_caller_identity.current.account_id
  kms_key_arn          = module.security.kms_key_arn
  cors_allowed_origins = var.cors_allowed_origins
}

# ─────────────────────────────────────────────
# Security Module (KMS + IAM)
# ─────────────────────────────────────────────

module "security" {
  source = "./modules/security"

  project_name        = var.project_name
  environment         = var.environment
  aws_region          = var.aws_region
  account_id          = data.aws_caller_identity.current.account_id
  dynamodb_table_arns = module.dynamodb.all_table_arns
  s3_bucket_arns      = module.s3.all_bucket_arns

  bedrock_model_ids = {
    claude_sonnet = var.bedrock_model_ids.claude_sonnet
    titan_text    = var.bedrock_model_ids.titan_text
  }
}

# ─────────────────────────────────────────────
# Amplify Module
# ─────────────────────────────────────────────

module "amplify" {
  source = "./modules/amplify"

  project_name    = var.project_name
  environment     = var.environment
  api_gateway_url = aws_api_gateway_stage.production.invoke_url

  github_repository = var.github_repository
  github_token      = var.github_token
}

# ─────────────────────────────────────────────
# Monitoring Module
# ─────────────────────────────────────────────

module "monitoring" {
  source = "./modules/monitoring"

  project_name           = var.project_name
  environment            = var.environment
  api_gateway_name       = aws_api_gateway_rest_api.bhashalens_api.name
  api_gateway_stage_name = aws_api_gateway_stage.production.stage_name

  lambda_function_names = [
    aws_lambda_function.translation.function_name,
    aws_lambda_function.assistance.function_name,
    aws_lambda_function.simplification.function_name,
    aws_lambda_function.authorizer.function_name,
    aws_lambda_function.history.function_name,
    aws_lambda_function.saved.function_name,
    aws_lambda_function.preferences.function_name,
    aws_lambda_function.export.function_name,
  ]

  dynamodb_table_names = [
    module.dynamodb.translation_history_table_name,
    module.dynamodb.saved_translations_table_name,
    module.dynamodb.user_preferences_table_name
  ]

  bedrock_model_ids = [
    var.bedrock_model_ids.claude_sonnet,
    var.bedrock_model_ids.titan_text,
    var.bedrock_model_ids.titan_embeddings
  ]

  alert_email = var.alert_email
}
