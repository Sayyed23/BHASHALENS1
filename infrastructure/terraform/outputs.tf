# Terraform Outputs for BhashaLens Infrastructure

# API Gateway Outputs
output "api_endpoint" {
  description = "Base URL for API Gateway endpoints"
  value       = "${aws_api_gateway_stage.production.invoke_url}/v1"
}

output "api_endpoints" {
  description = "All API endpoints"
  value = {
    translate = "${aws_api_gateway_stage.production.invoke_url}/v1/translate"
    assist    = "${aws_api_gateway_stage.production.invoke_url}/v1/assist"
    simplify  = "${aws_api_gateway_stage.production.invoke_url}/v1/simplify"
  }
}

# Lambda Function Outputs
output "lambda_functions" {
  description = "Lambda function details"
  value = {
    translation = {
      name = aws_lambda_function.translation.function_name
      arn  = aws_lambda_function.translation.arn
    }
    assistance = {
      name = aws_lambda_function.assistance.function_name
      arn  = aws_lambda_function.assistance.arn
    }
    simplification = {
      name = aws_lambda_function.simplification.function_name
      arn  = aws_lambda_function.simplification.arn
    }
  }
}

# DynamoDB Outputs
output "dynamodb_tables" {
  description = "DynamoDB table details"
  value = {
    user_preferences = {
      name = aws_dynamodb_table.user_preferences.name
      arn  = aws_dynamodb_table.user_preferences.arn
    }
    translation_history = {
      name = aws_dynamodb_table.translation_history.name
      arn  = aws_dynamodb_table.translation_history.arn
    }
    language_pack_metadata = {
      name = aws_dynamodb_table.language_pack_metadata.name
      arn  = aws_dynamodb_table.language_pack_metadata.arn
    }
  }
}

# S3 Outputs
output "s3_buckets" {
  description = "S3 bucket details"
  value = {
    language_packs = {
      name = aws_s3_bucket.language_packs.bucket
      arn  = aws_s3_bucket.language_packs.arn
    }
    logs = {
      name = aws_s3_bucket.logs.bucket
      arn  = aws_s3_bucket.logs.arn
    }
  }
}

# IAM Outputs
output "iam_roles" {
  description = "IAM role details"
  value = {
    lambda_execution = {
      name = aws_iam_role.lambda_execution_role.name
      arn  = aws_iam_role.lambda_execution_role.arn
    }
    api_gateway_cloudwatch = {
      name = aws_iam_role.api_gateway_cloudwatch_role.name
      arn  = aws_iam_role.api_gateway_cloudwatch_role.arn
    }
  }
}

# CloudWatch Outputs
output "cloudwatch_resources" {
  description = "CloudWatch resource details"
  value = {
    dashboard_name = aws_cloudwatch_dashboard.bhashalens_dashboard.dashboard_name
    dashboard_url  = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.bhashalens_dashboard.dashboard_name}"
    log_groups = {
      api_gateway     = aws_cloudwatch_log_group.api_gateway_logs.name
      translation     = aws_cloudwatch_log_group.translation_logs.name
      assistance      = aws_cloudwatch_log_group.assistance_logs.name
      simplification  = aws_cloudwatch_log_group.simplification_logs.name
      bedrock         = aws_cloudwatch_log_group.bedrock_logs.name
    }
  }
}

# Bedrock Outputs
output "bedrock_configuration" {
  description = "Bedrock model configuration"
  value = {
    models = {
      claude_sonnet    = var.bedrock_model_ids.claude_sonnet
      titan_text       = var.bedrock_model_ids.titan_text
      titan_embeddings = var.bedrock_model_ids.titan_embeddings
    }
    region = var.aws_region
  }
}

# Summary Output
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment     = var.environment
    region          = var.aws_region
    api_endpoint    = "${aws_api_gateway_stage.production.invoke_url}/v1"
    dashboard_url   = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.bhashalens_dashboard.dashboard_name}"
    s3_bucket       = aws_s3_bucket.language_packs.bucket
  }
}
