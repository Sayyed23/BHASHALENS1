# Lambda Functions for BhashaLens

# Data source for Lambda deployment package
data "archive_file" "lambda_translation" {
  type        = "zip"
  source_file = "${path.module}/../lambda/functions/translation_handler.py"
  output_path = "${path.module}/lambda_translation.zip"
}

data "archive_file" "lambda_assistance" {
  type        = "zip"
  source_file = "${path.module}/../lambda/functions/assistance_handler.py"
  output_path = "${path.module}/lambda_assistance.zip"
}

data "archive_file" "lambda_simplification" {
  type        = "zip"
  source_file = "${path.module}/../lambda/functions/simplification_handler.py"
  output_path = "${path.module}/lambda_simplification.zip"
}

data "archive_file" "lambda_authorizer" {
  type        = "zip"
  source_file = "${path.module}/../lambda/functions/authorizer.py"
  output_path = "${path.module}/lambda_authorizer.zip"
}

data "archive_file" "lambda_history" {
  type        = "zip"
  source_file = "${path.module}/../lambda/functions/history_handler.py"
  output_path = "${path.module}/lambda_history.zip"
}

data "archive_file" "lambda_saved" {
  type        = "zip"
  source_file = "${path.module}/../lambda/functions/saved_handler.py"
  output_path = "${path.module}/lambda_saved.zip"
}

data "archive_file" "lambda_preferences" {
  type        = "zip"
  source_file = "${path.module}/../lambda/functions/preferences_handler.py"
  output_path = "${path.module}/lambda_preferences.zip"
}

data "archive_file" "lambda_export" {
  type        = "zip"
  source_file = "${path.module}/../lambda/functions/export_handler.py"
  output_path = "${path.module}/lambda_export.zip"
}

# Translation Lambda Function
resource "aws_lambda_function" "translation" {
  filename         = data.archive_file.lambda_translation.output_path
  function_name    = "${var.project_name}-translation-handler"
  role             = module.security.lambda_execution_role_arn
  handler          = "translation_handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_translation.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      TRANSLATION_HISTORY_TABLE = module.dynamodb.translation_history_table_name
      BEDROCK_MODEL_ID          = var.bedrock_model_ids.claude_sonnet
    }
  }

  tags = {
    Name = "${var.project_name}-translation-handler"
  }
}

# Assistance Lambda Function
resource "aws_lambda_function" "assistance" {
  filename         = data.archive_file.lambda_assistance.output_path
  function_name    = "${var.project_name}-assistance-handler"
  role             = module.security.lambda_execution_role_arn
  handler          = "assistance_handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_assistance.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      BEDROCK_MODEL_ID = var.bedrock_model_ids.claude_sonnet
    }
  }

  tags = {
    Name = "${var.project_name}-assistance-handler"
  }
}

# Simplification Lambda Function
resource "aws_lambda_function" "simplification" {
  filename         = data.archive_file.lambda_simplification.output_path
  function_name    = "${var.project_name}-simplification-handler"
  role             = module.security.lambda_execution_role_arn
  handler          = "simplification_handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_simplification.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      BEDROCK_MODEL_ID = var.bedrock_model_ids.claude_sonnet
    }
  }

  tags = {
    Name = "${var.project_name}-simplification-handler"
  }
}

# Authorizer Lambda Function
resource "aws_lambda_function" "authorizer" {
  filename         = data.archive_file.lambda_authorizer.output_path
  function_name    = "${var.project_name}-authorizer"
  role             = module.security.lambda_execution_role_arn
  handler          = "authorizer.lambda_handler"
  source_code_hash = data.archive_file.lambda_authorizer.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  tags = {
    Name = "${var.project_name}-authorizer"
  }
}

# History Lambda Function
resource "aws_lambda_function" "history" {
  filename         = data.archive_file.lambda_history.output_path
  function_name    = "${var.project_name}-history-handler"
  role             = module.security.lambda_execution_role_arn
  handler          = "history_handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_history.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      TRANSLATION_HISTORY_TABLE = module.dynamodb.translation_history_table_name
    }
  }

  tags = {
    Name = "${var.project_name}-history-handler"
  }
}

# Saved Lambda Function
resource "aws_lambda_function" "saved" {
  filename         = data.archive_file.lambda_saved.output_path
  function_name    = "${var.project_name}-saved-handler"
  role             = module.security.lambda_execution_role_arn
  handler          = "saved_handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_saved.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      SAVED_TRANSLATIONS_TABLE = module.dynamodb.saved_translations_table_name
    }
  }

  tags = {
    Name = "${var.project_name}-saved-handler"
  }
}

# Preferences Lambda Function
resource "aws_lambda_function" "preferences" {
  filename         = data.archive_file.lambda_preferences.output_path
  function_name    = "${var.project_name}-preferences-handler"
  role             = module.security.lambda_execution_role_arn
  handler          = "preferences_handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_preferences.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      USER_PREFERENCES_TABLE = module.dynamodb.user_preferences_table_name
    }
  }

  tags = {
    Name = "${var.project_name}-preferences-handler"
  }
}

# Export Lambda Function
resource "aws_lambda_function" "export" {
  filename         = data.archive_file.lambda_export.output_path
  function_name    = "${var.project_name}-export-handler"
  role             = module.security.lambda_execution_role_arn
  handler          = "export_handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_export.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      TRANSLATION_HISTORY_TABLE = module.dynamodb.translation_history_table_name
      SAVED_TRANSLATIONS_TABLE  = module.dynamodb.saved_translations_table_name
      EXPORT_BUCKET_NAME        = module.s3.translation_exports_bucket_name
    }
  }

  tags = {
    Name = "${var.project_name}-export-handler"
  }
}

# CloudWatch Log Groups for Lambda functions
resource "aws_cloudwatch_log_group" "translation_logs" {
  name              = "/aws/lambda/${aws_lambda_function.translation.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name = "${var.project_name}-translation-logs"
  }
}

resource "aws_cloudwatch_log_group" "assistance_logs" {
  name              = "/aws/lambda/${aws_lambda_function.assistance.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name = "${var.project_name}-assistance-logs"
  }
}

resource "aws_cloudwatch_log_group" "simplification_logs" {
  name              = "/aws/lambda/${aws_lambda_function.simplification.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name = "${var.project_name}-simplification-logs"
  }
}

resource "aws_cloudwatch_log_group" "authorizer_logs" {
  name              = "/aws/lambda/${aws_lambda_function.authorizer.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name = "${var.project_name}-authorizer-logs"
  }
}

resource "aws_cloudwatch_log_group" "history_logs" {
  name              = "/aws/lambda/${aws_lambda_function.history.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name = "${var.project_name}-history-logs"
  }
}

resource "aws_cloudwatch_log_group" "saved_logs" {
  name              = "/aws/lambda/${aws_lambda_function.saved.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name = "${var.project_name}-saved-logs"
  }
}

resource "aws_cloudwatch_log_group" "preferences_logs" {
  name              = "/aws/lambda/${aws_lambda_function.preferences.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name = "${var.project_name}-preferences-logs"
  }
}

resource "aws_cloudwatch_log_group" "export_logs" {
  name              = "/aws/lambda/${aws_lambda_function.export.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name = "${var.project_name}-export-logs"
  }
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "translation_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.translation.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bhashalens_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "assistance_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.assistance.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bhashalens_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "simplification_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.simplification.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bhashalens_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "authorizer_api_gateway" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.bhashalens_api.id}/*/*"
}

resource "aws_lambda_permission" "history_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.history.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bhashalens_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "saved_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.saved.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bhashalens_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "preferences_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.preferences.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bhashalens_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "export_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.export.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bhashalens_api.execution_arn}/*/*"
}

# Outputs
output "translation_lambda_arn" {
  description = "ARN of translation Lambda function"
  value       = aws_lambda_function.translation.arn
}

output "assistance_lambda_arn" {
  description = "ARN of assistance Lambda function"
  value       = aws_lambda_function.assistance.arn
}

output "simplification_lambda_arn" {
  description = "ARN of simplification Lambda function"
  value       = aws_lambda_function.simplification.arn
}

output "authorizer_lambda_arn" {
  description = "ARN of authorizer Lambda function"
  value       = aws_lambda_function.authorizer.arn
}

output "history_lambda_arn" {
  description = "ARN of history Lambda function"
  value       = aws_lambda_function.history.arn
}

output "saved_lambda_arn" {
  description = "ARN of saved Lambda function"
  value       = aws_lambda_function.saved.arn
}

output "preferences_lambda_arn" {
  description = "ARN of preferences Lambda function"
  value       = aws_lambda_function.preferences.arn
}

output "export_lambda_arn" {
  description = "ARN of export Lambda function"
  value       = aws_lambda_function.export.arn
}
