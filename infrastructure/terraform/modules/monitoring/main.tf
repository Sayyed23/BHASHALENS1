# CloudWatch Monitoring and Alarms Configuration

# SNS Topic for Alarms
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts-${var.environment}"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Generate CloudWatch Dashboard JSON dynamically
locals {
  # Helper to generate Lambda widgets
  lambda_widgets = flatten([
    for idx, fn_name in var.lambda_function_names : [
      {
        type   = "metric"
        x      = (idx * 6) % 24
        y      = floor((idx * 6) / 24) * 6 + 6
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", fn_name, { "stat" : "Sum", "color" : "#1f77b4" }],
            [".", "Errors", ".", ".", { "stat" : "Sum", "color" : "#d62728" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "${fn_name} Metrics"
          period  = 300
        }
      }
    ]
  ])

  # Helper to generate DynamoDB widgets
  dynamo_widgets = flatten([
    for idx, table_name in var.dynamodb_table_names : [
      {
        type   = "metric"
        x      = (idx * 8) % 24
        y      = floor((idx * 8) / 24) * 6 + 18
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", table_name, { "stat" : "Sum" }],
            [".", "ConsumedWriteCapacityUnits", ".", ".", { "stat" : "Sum" }]
          ]
          view   = "timeSeries"
          region = data.aws_region.current.name
          title  = "${table_name} Capacity"
          period = 300
        }
      }
    ]
  ])
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard-${var.environment}"

  dashboard_body = jsonencode({
    widgets = concat(
      [
        {
          type   = "metric"
          x      = 0
          y      = 0
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_name, { "stat" : "Sum" }],
              [".", "4XXError", ".", ".", { "stat" : "Sum" }],
              [".", "5XXError", ".", ".", { "stat" : "Sum" }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "API Gateway Requests & Errors"
            period  = 300
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 0
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApiGateway", "Latency", "ApiName", var.api_gateway_name, { "stat" : "p50" }],
              ["...", { "stat" : "p95" }],
              ["...", { "stat" : "p99" }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = data.aws_region.current.name
            title   = "API Gateway Latency"
            period  = 300
          }
        }
      ],
      local.lambda_widgets,
      local.dynamo_widgets,
      # Optional Bedrock widgets
      [
        {
          type   = "metric"
          x      = 0
          y      = 24
          width  = 12
          height = 6
          properties = {
            metrics = [
              for model_id in var.bedrock_model_ids :
              ["AWS/Bedrock", "InvocationCount", "ModelId", model_id, { "stat" : "Sum" }]
            ]
            view   = "timeSeries"
            region = data.aws_region.current.name
            title  = "Bedrock Invocations"
            period = 300
          }
        }
      ]
    )
  })
}

# --- Alarms ---

# API Gateway 5XX Errors Alarm
resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "${var.project_name}-api-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors API Gateway 5XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.api_gateway_stage_name
  }
}

# API Gateway Latency Alarm
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.project_name}-api-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000" # 5 seconds
  alarm_description   = "API Gateway latency has exceeded 5 seconds"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.api_gateway_stage_name
  }
}

# Lambda Errors Alarm (combined for all functions)
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  alarm_description   = "More than 5 Lambda errors in 5 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id          = "e1"
    expression  = "SUM(METRICS())"
    label       = "Total Lambda Errors"
    return_data = true
  }

  dynamic "metric_query" {
    for_each = var.lambda_function_names
    content {
      id = "m${metric_query.key}"
      metric {
        metric_name = "Errors"
        namespace   = "AWS/Lambda"
        period      = "300"
        stat        = "Sum"
        dimensions = {
          FunctionName = metric_query.value
        }
      }
    }
  }

  threshold = "5"
}

# Cost Budgets
resource "aws_budgets_budget" "monthly_cost" {
  count             = var.alert_email != "" ? 1 : 0
  name              = "${var.project_name}-monthly-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.budget_limit_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.budget_warning_threshold
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}

data "aws_region" "current" {}
