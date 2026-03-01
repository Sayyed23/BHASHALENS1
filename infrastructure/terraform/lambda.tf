# Lambda Functions for BhashaLens

# Data source for Lambda deployment package
data "archive_file" "lambda_translation" {
  type        = "zip"
  source_file = "${path.module}/../lambda/translation_handler.py"
  output_path = "${path.module}/lambda_translation.zip"
}

data "archive_file" "lambda_assistance" {
  type        = "zip"
  source_file = "${path.module}/../lambda/assistance_handler.py"
  output_path = "${path.module}/lambda_assistance.zip"
}

data "archive_file" "lambda_simplification" {
  type        = "zip"
  source_file = "${path.module}/../lambda/simplification_handler.py"
  output_path = "${path.module}/lambda_simplification.zip"
}

# Translation Lambda Function
resource "aws_lambda_function" "translation" {
  filename         = data.archive_file.lambda_translation.output_path
  function_name    = "${var.project_name}-translation-handler"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "translation_handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_translation.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  
  environment {
    variables = {
      AWS_REGION                  = var.aws_region
      TRANSLATION_HISTORY_TABLE   = aws_dynamodb_table.translation_history.name
      BEDROCK_MODEL_ID           = var.bedrock_model_ids.claude_sonnet
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
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "assistance_handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_assistance.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  
  environment {
    variables = {
      AWS_REGION       = var.aws_region
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
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "simplification_handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_simplification.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  
  environment {
    variables = {
      AWS_REGION       = var.aws_region
      BEDROCK_MODEL_ID = var.bedrock_model_ids.claude_sonnet
    }
  }
  
  tags = {
    Name = "${var.project_name}-simplification-handler"
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
