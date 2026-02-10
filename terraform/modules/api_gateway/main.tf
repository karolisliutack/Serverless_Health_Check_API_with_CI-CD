# API Gateway Module - Creates HTTP API with throttling

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.environment}-health-check-api"
  protocol_type = "HTTP"

  tags = {
    Name = "${var.environment}-health-check-api"
  }
}

# API Gateway stage with throttling (DDoS protection)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = var.throttle_rate_limit
    throttling_burst_limit = var.throttle_burst_limit
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }
}

# Lambda integration
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Health route for GET requests
resource "aws_apigatewayv2_route" "health_get" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Health route for POST requests
resource "aws_apigatewayv2_route" "health_post" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.environment}-health-check-api"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.environment}-api-gateway-logs"
  }
}
