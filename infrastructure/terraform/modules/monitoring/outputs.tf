output "dashboard_arn" {
  description = "ARN of the dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "sns_alerts_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}
