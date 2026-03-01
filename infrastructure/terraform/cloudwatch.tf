# CloudWatch Monitoring and Alarms for BhashaLens

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "bhashalens_dashboard" {
  dashboard_name = "${var.project_name}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Translation Invocations" }],
            [".", ".", { stat = "Sum", label = "Assistance Invocations" }],
            [".", ".", { stat = "Sum", label = "Simplification Invocations" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Invocations"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", { stat = "Average", label = "Translation Duration" }],
            [".", ".", { stat = "Average", label = "Assistance Duration" }],
            [".", ".", { stat = "Average", label = "Simplification Duration" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Lambda Duration (ms)"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", { stat = "Sum", label = "Translation Errors" }],
            [".", ".", { stat = "Sum", label = "Assistance Errors" }],
            [".", ".", { stat = "Sum", label = "Simplification Errors" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Errors"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { stat = "Sum" }],
            [".", "4XXError", { stat = "Sum" }],
            [".", "5XXError", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway Requests"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency", { stat = "Average" }],
            [".", "IntegrationLatency", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "API Gateway Latency (ms)"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum" }],
            [".", "ConsumedWriteCapacityUnits", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB Capacity Units"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["BhashaLens", "ProcessingTime", { stat = "Average", dimensions = { Operation = "Translation" } }],
            [".", ".", { stat = "Average", dimensions = { Operation = "Assistance_grammar" } }],
            [".", ".", { stat = "Average", dimensions = { Operation = "Simplification" } }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Custom Processing Time (ms)"
        }
      }
    ]
  })
}

# Lambda Function Alarms

# Translation Lambda Errors
resource "aws_cloudwatch_metric_alarm" "translation_lambda_errors" {
  alarm_name          = "${var.project_name}-translation-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when translation Lambda has errors"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = aws_lambda_function.translation.function_name
  }
  
  tags = {
    Name = "${var.project_name}-translation-lambda-errors"
  }
}

# Translation Lambda Duration
resource "aws_cloudwatch_metric_alarm" "translation_lambda_duration" {
  alarm_name          = "${var.project_name}-translation-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"  # 5 seconds
  alarm_description   = "Alert when translation Lambda duration exceeds 5 seconds"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = aws_lambda_function.translation.function_name
  }
  
  tags = {
    Name = "${var.project_name}-translation-lambda-duration"
  }
}

# Assistance Lambda Errors
resource "aws_cloudwatch_metric_alarm" "assistance_lambda_errors" {
  alarm_name          = "${var.project_name}-assistance-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when assistance Lambda has errors"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = aws_lambda_function.assistance.function_name
  }
  
  tags = {
    Name = "${var.project_name}-assistance-lambda-errors"
  }
}

# Simplification Lambda Errors
resource "aws_cloudwatch_metric_alarm" "simplification_lambda_errors" {
  alarm_name          = "${var.project_name}-simplification-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when simplification Lambda has errors"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = aws_lambda_function.simplification.function_name
  }
  
  tags = {
    Name = "${var.project_name}-simplification-lambda-errors"
  }
}

# API Gateway Alarms

# API Gateway 5XX Errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  alarm_name          = "${var.project_name}-api-gateway-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when API Gateway has 5XX errors"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    ApiName = aws_api_gateway_rest_api.bhashalens_api.name
  }
  
  tags = {
    Name = "${var.project_name}-api-gateway-5xx-errors"
  }
}

# API Gateway Latency
resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  alarm_name          = "${var.project_name}-api-gateway-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"  # 5 seconds
  alarm_description   = "Alert when API Gateway latency exceeds 5 seconds"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    ApiName = aws_api_gateway_rest_api.bhashalens_api.name
  }
  
  tags = {
    Name = "${var.project_name}-api-gateway-latency"
  }
}

# DynamoDB Alarms

# DynamoDB User Errors
resource "aws_cloudwatch_metric_alarm" "dynamodb_user_errors" {
  alarm_name          = "${var.project_name}-dynamodb-user-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when DynamoDB has user errors"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    TableName = aws_dynamodb_table.translation_history.name
  }
  
  tags = {
    Name = "${var.project_name}-dynamodb-user-errors"
  }
}

# DynamoDB System Errors
resource "aws_cloudwatch_metric_alarm" "dynamodb_system_errors" {
  alarm_name          = "${var.project_name}-dynamodb-system-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SystemErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when DynamoDB has system errors"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    TableName = aws_dynamodb_table.translation_history.name
  }
  
  tags = {
    Name = "${var.project_name}-dynamodb-system-errors"
  }
}

# Outputs
output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.bhashalens_dashboard.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.bhashalens_dashboard.dashboard_name}"
}
