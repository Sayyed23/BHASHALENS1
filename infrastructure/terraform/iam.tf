# IAM Roles and Policies for BhashaLens

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.project_name}-lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.project_name}-lambda-execution-role"
  }
}

# Lambda Basic Execution Policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom Lambda Policy for BhashaLens Services
resource "aws_iam_policy" "lambda_bhashalens_policy" {
  name        = "${var.project_name}-lambda-policy"
  description = "Policy for BhashaLens Lambda functions to access AWS services"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockAccess"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_ids.claude_sonnet}",
          "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_ids.titan_text}",
          "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_ids.titan_embeddings}"
        ]
      },
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.user_preferences.arn,
          aws_dynamodb_table.translation_history.arn,
          aws_dynamodb_table.language_pack_metadata.arn,
          "${aws_dynamodb_table.translation_history.arn}/index/*"
        ]
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.language_packs.arn,
          "${aws_s3_bucket.language_packs.arn}/*"
        ]
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach custom policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_bhashalens_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_bhashalens_policy.arn
}

# API Gateway CloudWatch Logs Role
resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "${var.project_name}-api-gateway-cloudwatch-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# Attach CloudWatch Logs policy to API Gateway role
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Output IAM role ARNs
output "lambda_execution_role_arn" {
  description = "ARN of Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "api_gateway_cloudwatch_role_arn" {
  description = "ARN of API Gateway CloudWatch role"
  value       = aws_iam_role.api_gateway_cloudwatch_role.arn
}
