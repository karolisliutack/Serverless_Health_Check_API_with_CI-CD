# API Gateway endpoint URL
output "api_endpoint" {
  description = "API Gateway endpoint URL for health check"
  value       = module.api_gateway.api_endpoint
}

# Lambda function ARN
output "lambda_function_arn" {
  description = "ARN of the health check Lambda function"
  value       = module.lambda.function_arn
}

# Lambda function name
output "lambda_function_name" {
  description = "Name of the health check Lambda function"
  value       = module.lambda.function_name
}

# DynamoDB table name
output "dynamodb_table_name" {
  description = "Name of the DynamoDB requests table"
  value       = module.dynamodb.table_name
}

# DynamoDB table ARN
output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB requests table"
  value       = module.dynamodb.table_arn
}

# KMS key ARN
output "kms_key_arn" {
  description = "ARN of the KMS key used for DynamoDB encryption"
  value       = module.dynamodb.kms_key_arn
}

# CloudWatch Log Group for Lambda
output "lambda_log_group" {
  description = "CloudWatch Log Group for Lambda function"
  value       = module.lambda.log_group_name
}

# VPC ID (if enabled)
output "vpc_id" {
  description = "VPC ID for Lambda function"
  value       = module.vpc.vpc_id
}

# API Key (if enabled)
output "api_key" {
  description = "API key for authenticating requests"
  value       = module.lambda.api_key
  sensitive   = true
}
