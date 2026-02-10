variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (staging or prod)"
  type        = string
  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "Environment must be either 'staging' or 'prod'."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "health-check"
}

variable "dynamodb_read_capacity" {
  description = "DynamoDB read capacity units"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "DynamoDB write capacity units"
  type        = number
  default     = 5
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 100
}

variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 200
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
  validation {
    condition     = var.lambda_timeout > 0 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256
  validation {
    condition     = contains([128, 256, 512, 1024, 1536, 3008], var.lambda_memory_size)
    error_message = "Lambda memory must be a valid value."
  }
}

variable "enable_api_key" {
  description = "Enable API key authentication"
  type        = bool
  default     = true
}

variable "api_key_secret" {
  description = "API key secret for authentication (provide via tfvars or environment variable)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_vpc" {
  description = "Enable VPC configuration for Lambda function"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
