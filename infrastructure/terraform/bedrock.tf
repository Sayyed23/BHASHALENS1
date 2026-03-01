# Amazon Bedrock Configuration for BhashaLens

# Note: Amazon Bedrock models are managed by AWS and don't require explicit resource creation
# However, you need to enable model access in the AWS Console or via AWS CLI
# This file documents the models used and provides outputs for reference

# Bedrock Model IDs used by BhashaLens
locals {
  bedrock_models = {
    claude_sonnet = {
      model_id    = var.bedrock_model_ids.claude_sonnet
      description = "Claude 3 Sonnet - Primary model for translation, assistance, and simplification"
      use_cases   = ["translation", "grammar_check", "qa", "conversation", "simplification"]
    }
    titan_text = {
      model_id    = var.bedrock_model_ids.titan_text
      description = "Amazon Titan Text Premier - Alternative model for text generation"
      use_cases   = ["text_generation", "summarization"]
    }
    titan_embeddings = {
      model_id    = var.bedrock_model_ids.titan_embeddings
      description = "Amazon Titan Embeddings - For semantic search and similarity"
      use_cases   = ["embeddings", "semantic_search"]
    }
  }
}

# CloudWatch Log Group for Bedrock model invocations
resource "aws_cloudwatch_log_group" "bedrock_logs" {
  name              = "/aws/bedrock/${var.project_name}"
  retention_in_days = var.cloudwatch_log_retention_days
  
  tags = {
    Name = "${var.project_name}-bedrock-logs"
  }
}

# CloudWatch Alarms for Bedrock usage
resource "aws_cloudwatch_metric_alarm" "bedrock_throttling" {
  alarm_name          = "${var.project_name}-bedrock-throttling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ModelInvocationThrottles"
  namespace           = "AWS/Bedrock"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when Bedrock model invocations are being throttled"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    ModelId = var.bedrock_model_ids.claude_sonnet
  }
  
  tags = {
    Name = "${var.project_name}-bedrock-throttling-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "bedrock_errors" {
  alarm_name          = "${var.project_name}-bedrock-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ModelInvocationClientErrors"
  namespace           = "AWS/Bedrock"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when Bedrock model invocations have client errors"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    ModelId = var.bedrock_model_ids.claude_sonnet
  }
  
  tags = {
    Name = "${var.project_name}-bedrock-errors-alarm"
  }
}

# Outputs
output "bedrock_models" {
  description = "Bedrock models configuration"
  value = {
    for key, model in local.bedrock_models : key => {
      model_id    = model.model_id
      description = model.description
      use_cases   = model.use_cases
    }
  }
}

output "bedrock_model_arns" {
  description = "ARNs of Bedrock models"
  value = {
    claude_sonnet    = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_ids.claude_sonnet}"
    titan_text       = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_ids.titan_text}"
    titan_embeddings = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_ids.titan_embeddings}"
  }
}
