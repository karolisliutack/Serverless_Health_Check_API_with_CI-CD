output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.requests.name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.requests.arn
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.dynamodb.arn
}

output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.dynamodb.key_id
}
