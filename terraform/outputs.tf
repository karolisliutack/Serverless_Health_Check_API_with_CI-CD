# API Gateway endpoint URL
output "api_endpoint" {
  description = "API Gateway endpoint URL for health check"
  value       = "${aws_apigatewayv2_api.health_check.api_endpoint}/health"
}

# Lambda function ARN
output "lambda_function_arn" {
  description = "ARN of the health check Lambda function"
  value       = aws_lambda_function.health_check.arn
}

# Lambda function name
output "lambda_function_name" {
  description = "Name of the health check Lambda function"
  value       = aws_lambda_function.health_check.function_name
}

# DynamoDB table name
output "dynamodb_table_name" {
  description = "Name of the DynamoDB requests table"
  value       = aws_dynamodb_table.requests.name
}

# DynamoDB table ARN
output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB requests table"
  value       = aws_dynamodb_table.requests.arn
}

# KMS key ARN
output "kms_key_arn" {
  description = "ARN of the KMS key used for DynamoDB encryption"
  value       = aws_kms_key.dynamodb.arn
}

# CloudWatch Log Group for Lambda
output "lambda_log_group" {
  description = "CloudWatch Log Group for Lambda function"
  value       = aws_cloudwatch_log_group.lambda.name
}

# VPC ID (if enabled)
output "vpc_id" {
  description = "VPC ID for Lambda function"
  value       = var.enable_vpc ? aws_vpc.lambda[0].id : null
}

# API Key (if enabled)
output "api_key" {
  description = "API key for authenticating requests"
  value       = var.enable_api_key ? random_password.api_key[0].result : null
  sensitive   = true
}
