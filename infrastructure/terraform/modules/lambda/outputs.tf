output "authorizer_function_arn" {
  value = aws_lambda_function.authorizer.arn
}

output "authorizer_function_name" {
  value = aws_lambda_function.authorizer.function_name
}

output "translation_function_arn" {
  value = aws_lambda_function.translation.arn
}

output "translation_function_name" {
  value = aws_lambda_function.translation.function_name
}

output "assistance_function_arn" {
  value = aws_lambda_function.assistance.arn
}

output "simplification_function_arn" {
  value = aws_lambda_function.simplification.arn
}

output "history_function_arn" {
  value = aws_lambda_function.history.arn
}

output "saved_function_arn" {
  value = aws_lambda_function.saved.arn
}

output "preferences_function_arn" {
  value = aws_lambda_function.preferences.arn
}

output "export_function_arn" {
  value = aws_lambda_function.export.arn
}
