variable "environment" {
  description = "Environment name (staging or prod)"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "lambda_role_arn" {
  description = "Lambda execution role ARN for KMS access"
  type        = string
}

variable "read_capacity" {
  description = "DynamoDB read capacity units"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "DynamoDB write capacity units"
  type        = number
  default     = 5
}
