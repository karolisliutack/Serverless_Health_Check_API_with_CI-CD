# Main Terraform configuration using reusable modules
# This file orchestrates all modules and handles dependencies

# Archive the Lambda source code
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda.zip"
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# IAM Role (created first to resolve circular dependencies)
# ============================================================================

resource "aws_iam_role" "lambda_execution" {
  name = "${var.environment}-health-check-lambda-role"

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
    Name = "${var.environment}-health-check-lambda-role"
  }
}

# ============================================================================
# VPC Module
# ============================================================================

module "vpc" {
  source = "./modules/vpc"

  environment = var.environment
  enabled     = var.enable_vpc
  vpc_cidr    = var.vpc_cidr
  aws_region  = var.aws_region
}

# ============================================================================
# DynamoDB Module
# ============================================================================

module "dynamodb" {
  source = "./modules/dynamodb"

  environment     = var.environment
  account_id      = data.aws_caller_identity.current.account_id
  lambda_role_arn = aws_iam_role.lambda_execution.arn
  read_capacity   = var.dynamodb_read_capacity
  write_capacity  = var.dynamodb_write_capacity
}

# ============================================================================
# Lambda Module
# ============================================================================

module "lambda" {
  source = "./modules/lambda"

  environment         = var.environment
  lambda_role_arn     = aws_iam_role.lambda_execution.arn
  lambda_role_id      = aws_iam_role.lambda_execution.id
  lambda_zip_path     = data.archive_file.lambda.output_path
  lambda_source_hash  = data.archive_file.lambda.output_base64sha256
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn
  kms_key_arn         = module.dynamodb.kms_key_arn
  enable_api_key      = var.enable_api_key
  enable_vpc          = var.enable_vpc
  subnet_ids          = module.vpc.subnet_ids
  security_group_id   = module.vpc.security_group_id
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory_size

  depends_on = [module.dynamodb, module.vpc]
}

# ============================================================================
# API Gateway Module
# ============================================================================

module "api_gateway" {
  source = "./modules/api_gateway"

  environment          = var.environment
  lambda_invoke_arn    = module.lambda.invoke_arn
  throttle_rate_limit  = var.api_throttle_rate_limit
  throttle_burst_limit = var.api_throttle_burst_limit

  depends_on = [module.lambda]
}

# ============================================================================
# Lambda Permission for API Gateway
# ============================================================================

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.execution_arn}/*/*"
}
