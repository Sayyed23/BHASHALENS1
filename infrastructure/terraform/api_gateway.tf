# API Gateway for BhashaLens

# REST API
resource "aws_api_gateway_rest_api" "bhashalens_api" {
  name        = "${var.project_name}-api"
  description = "BhashaLens Cloud API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

# API Gateway Account (for CloudWatch logging)
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = module.security.api_gateway_cloudwatch_role_arn
}

# API Gateway Authorizer
resource "aws_api_gateway_authorizer" "firebase_auth" {
  name            = "firebase_authorizer"
  rest_api_id     = aws_api_gateway_rest_api.bhashalens_api.id
  authorizer_uri  = aws_lambda_function.authorizer.invoke_arn
  identity_source = "method.request.header.Authorization"
  type            = "TOKEN"
}

# Request Validator
resource "aws_api_gateway_request_validator" "body_validator" {
  name                        = "body-validator"
  rest_api_id                 = aws_api_gateway_rest_api.bhashalens_api.id
  validate_request_body       = true
  validate_request_parameters = false
}

# /v1 resource
resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id
  parent_id   = aws_api_gateway_rest_api.bhashalens_api.root_resource_id
  path_part   = "v1"
}

# /v1/translate resource
resource "aws_api_gateway_resource" "translate" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "translate"
}

# POST /v1/translate method
resource "aws_api_gateway_method" "translate_post" {
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id   = aws_api_gateway_resource.translate.id
  http_method   = "POST"
  authorization = "NONE"
}

# Translation Lambda integration
resource "aws_api_gateway_integration" "translate_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id             = aws_api_gateway_resource.translate.id
  http_method             = aws_api_gateway_method.translate_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.translation.invoke_arn
}

# /v1/assist resource
resource "aws_api_gateway_resource" "assist" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "assist"
}

# POST /v1/assist method
resource "aws_api_gateway_method" "assist_post" {
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id   = aws_api_gateway_resource.assist.id
  http_method   = "POST"
  authorization = "NONE"
}

# Assistance Lambda integration
resource "aws_api_gateway_integration" "assist_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id             = aws_api_gateway_resource.assist.id
  http_method             = aws_api_gateway_method.assist_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.assistance.invoke_arn
}

# /v1/simplify resource
resource "aws_api_gateway_resource" "simplify" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "simplify"
}

# POST /v1/simplify method
resource "aws_api_gateway_method" "simplify_post" {
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id   = aws_api_gateway_resource.simplify.id
  http_method   = "POST"
  authorization = "NONE"
}

# Simplification Lambda integration
resource "aws_api_gateway_integration" "simplify_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id             = aws_api_gateway_resource.simplify.id
  http_method             = aws_api_gateway_method.simplify_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.simplification.invoke_arn
}

# /v1/history resource
resource "aws_api_gateway_resource" "history" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "history"
}

# GET /v1/history
resource "aws_api_gateway_method" "history_get" {
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id   = aws_api_gateway_resource.history.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.firebase_auth.id
}

resource "aws_api_gateway_integration" "history_get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id             = aws_api_gateway_resource.history.id
  http_method             = aws_api_gateway_method.history_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.history.invoke_arn
}

# /v1/history/{id} resource
resource "aws_api_gateway_resource" "history_id" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id
  parent_id   = aws_api_gateway_resource.history.id
  path_part   = "{id}"
}

# DELETE /v1/history/{id}
resource "aws_api_gateway_method" "history_delete" {
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id   = aws_api_gateway_resource.history_id.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.firebase_auth.id
}

resource "aws_api_gateway_integration" "history_delete_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id             = aws_api_gateway_resource.history_id.id
  http_method             = aws_api_gateway_method.history_delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.history.invoke_arn
}

# /v1/saved resource
resource "aws_api_gateway_resource" "saved" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "saved"
}

# GET /v1/saved
resource "aws_api_gateway_method" "saved_get" {
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id   = aws_api_gateway_resource.saved.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.firebase_auth.id
}

resource "aws_api_gateway_integration" "saved_get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id             = aws_api_gateway_resource.saved.id
  http_method             = aws_api_gateway_method.saved_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.saved.invoke_arn
}

# POST /v1/saved
resource "aws_api_gateway_method" "saved_post" {
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id   = aws_api_gateway_resource.saved.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.firebase_auth.id
}

resource "aws_api_gateway_integration" "saved_post_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id             = aws_api_gateway_resource.saved.id
  http_method             = aws_api_gateway_method.saved_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.saved.invoke_arn
}

# /v1/saved/{id} resource
resource "aws_api_gateway_resource" "saved_id" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id
  parent_id   = aws_api_gateway_resource.saved.id
  path_part   = "{id}"
}

# DELETE /v1/saved/{id}
resource "aws_api_gateway_method" "saved_delete" {
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id   = aws_api_gateway_resource.saved_id.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.firebase_auth.id
}

resource "aws_api_gateway_integration" "saved_delete_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id             = aws_api_gateway_resource.saved_id.id
  http_method             = aws_api_gateway_method.saved_delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.saved.invoke_arn
}

# /v1/preferences resource
resource "aws_api_gateway_resource" "preferences" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "preferences"
}

# GET /v1/preferences
resource "aws_api_gateway_method" "preferences_get" {
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id   = aws_api_gateway_resource.preferences.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.firebase_auth.id
}

resource "aws_api_gateway_integration" "preferences_get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id             = aws_api_gateway_resource.preferences.id
  http_method             = aws_api_gateway_method.preferences_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.preferences.invoke_arn
}

# PUT /v1/preferences
resource "aws_api_gateway_method" "preferences_put" {
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id   = aws_api_gateway_resource.preferences.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.firebase_auth.id
}

resource "aws_api_gateway_integration" "preferences_put_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id             = aws_api_gateway_resource.preferences.id
  http_method             = aws_api_gateway_method.preferences_put.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.preferences.invoke_arn
}

# /v1/export resource
resource "aws_api_gateway_resource" "export" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "export"
}

# POST /v1/export
resource "aws_api_gateway_method" "export_post" {
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id   = aws_api_gateway_resource.export.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.firebase_auth.id
}

resource "aws_api_gateway_integration" "export_post_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bhashalens_api.id
  resource_id             = aws_api_gateway_resource.export.id
  http_method             = aws_api_gateway_method.export_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.export.invoke_arn
}

# CORS configuration for all endpoints
module "cors_translate" {
  source = "./modules/cors"

  api_id          = aws_api_gateway_rest_api.bhashalens_api.id
  api_resource_id = aws_api_gateway_resource.translate.id
}

module "cors_assist" {
  source = "./modules/cors"

  api_id          = aws_api_gateway_rest_api.bhashalens_api.id
  api_resource_id = aws_api_gateway_resource.assist.id
}

module "cors_simplify" {
  source = "./modules/cors"

  api_id          = aws_api_gateway_rest_api.bhashalens_api.id
  api_resource_id = aws_api_gateway_resource.simplify.id
}

module "cors_history" {
  source = "./modules/cors"

  api_id          = aws_api_gateway_rest_api.bhashalens_api.id
  api_resource_id = aws_api_gateway_resource.history.id
}

module "cors_history_id" {
  source = "./modules/cors"

  api_id          = aws_api_gateway_rest_api.bhashalens_api.id
  api_resource_id = aws_api_gateway_resource.history_id.id
}

module "cors_saved" {
  source = "./modules/cors"

  api_id          = aws_api_gateway_rest_api.bhashalens_api.id
  api_resource_id = aws_api_gateway_resource.saved.id
}

module "cors_saved_id" {
  source = "./modules/cors"

  api_id          = aws_api_gateway_rest_api.bhashalens_api.id
  api_resource_id = aws_api_gateway_resource.saved_id.id
}

module "cors_preferences" {
  source = "./modules/cors"

  api_id          = aws_api_gateway_rest_api.bhashalens_api.id
  api_resource_id = aws_api_gateway_resource.preferences.id
}

module "cors_export" {
  source = "./modules/cors"

  api_id          = aws_api_gateway_rest_api.bhashalens_api.id
  api_resource_id = aws_api_gateway_resource.export.id
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "production" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id

  depends_on = [
    aws_api_gateway_integration.translate_lambda,
    aws_api_gateway_integration.assist_lambda,
    aws_api_gateway_integration.simplify_lambda,
    aws_api_gateway_integration.history_get_lambda,
    aws_api_gateway_integration.history_delete_lambda,
    aws_api_gateway_integration.saved_get_lambda,
    aws_api_gateway_integration.saved_post_lambda,
    aws_api_gateway_integration.saved_delete_lambda,
    aws_api_gateway_integration.preferences_get_lambda,
    aws_api_gateway_integration.preferences_put_lambda,
    aws_api_gateway_integration.export_post_lambda,
    module.cors_translate,
    module.cors_assist,
    module.cors_simplify,
    module.cors_history,
    module.cors_history_id,
    module.cors_saved,
    module.cors_saved_id,
    module.cors_preferences,
    module.cors_export,
  ]
  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "production" {
  deployment_id = aws_api_gateway_deployment.production.id
  rest_api_id   = aws_api_gateway_rest_api.bhashalens_api.id
  stage_name    = var.environment

  # Enable CloudWatch logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name = "${var.project_name}-api-${var.environment}"
  }
}

# Method settings for throttling and logging
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.bhashalens_api.id
  stage_name  = aws_api_gateway_stage.production.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    data_trace_enabled     = true
    throttling_rate_limit  = var.api_throttle_rate_limit
    throttling_burst_limit = var.api_throttle_burst_limit
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}-api"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name = "${var.project_name}-api-gateway-logs"
  }
}

# Outputs
output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = aws_api_gateway_stage.production.invoke_url
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.bhashalens_api.id
}

output "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.production.stage_name
}
