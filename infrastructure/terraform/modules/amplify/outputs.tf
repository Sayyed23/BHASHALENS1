output "amplify_app_id" {
  description = "ID of the Amplify App"
  value       = aws_amplify_app.bhashalens_web.id
}

output "amplify_app_arn" {
  description = "ARN of the Amplify App"
  value       = aws_amplify_app.bhashalens_web.arn
}

output "amplify_default_domain" {
  description = "Default domain for the Amplify App"
  value       = aws_amplify_app.bhashalens_web.default_domain
}

output "amplify_branch_url" {
  description = "URL of the deployed branch"
  value       = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_app.bhashalens_web.default_domain}"
}
