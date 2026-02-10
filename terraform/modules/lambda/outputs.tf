output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.health_check.arn
}

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.health_check.function_name
}

output "invoke_arn" {
  description = "Lambda invoke ARN"
  value       = aws_lambda_function.health_check.invoke_arn
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "api_key" {
  description = "API key for authentication"
  value       = var.enable_api_key ? random_password.api_key[0].result : null
  sensitive   = true
}
