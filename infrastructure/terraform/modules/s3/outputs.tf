# S3 Module Outputs

output "translation_exports_bucket_name" {
  description = "Name of the Translation Exports bucket"
  value       = aws_s3_bucket.translation_exports.bucket
}

output "translation_exports_bucket_arn" {
  description = "ARN of the Translation Exports bucket"
  value       = aws_s3_bucket.translation_exports.arn
}

output "static_assets_bucket_name" {
  description = "Name of the Static Assets bucket"
  value       = aws_s3_bucket.static_assets.bucket
}

output "static_assets_bucket_arn" {
  description = "ARN of the Static Assets bucket"
  value       = aws_s3_bucket.static_assets.arn
}

output "all_bucket_arns" {
  description = "List of all S3 bucket ARNs"
  value = [
    aws_s3_bucket.translation_exports.arn,
    aws_s3_bucket.static_assets.arn
  ]
}
