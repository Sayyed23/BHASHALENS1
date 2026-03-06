# Security Module Outputs

output "kms_key_arn" {
  description = "ARN of the KMS encryption key"
  value       = aws_kms_key.main.arn
}

output "kms_key_id" {
  description = "ID of the KMS encryption key"
  value       = aws_kms_key.main.key_id
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution IAM role"
  value       = aws_iam_role.lambda_execution.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution IAM role"
  value       = aws_iam_role.lambda_execution.name
}

output "api_gateway_cloudwatch_role_arn" {
  description = "ARN of the API Gateway CloudWatch IAM role"
  value       = aws_iam_role.api_gateway_cloudwatch.arn
}
