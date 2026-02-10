# Lambda Module - Creates Lambda function with IAM policies

# Generate API key for authentication
resource "random_password" "api_key" {
  count   = var.enable_api_key ? 1 : 0
  length  = 32
  special = false
}

# Policy for CloudWatch Logs - least privilege
resource "aws_iam_role_policy" "lambda_logging" {
  name = "${var.environment}-lambda-logging-policy"
  role = var.lambda_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      }
    ]
  })
}

# Policy for DynamoDB - least privilege
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.environment}-lambda-dynamodb-policy"
  role = var.lambda_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

# Policy for KMS - least privilege
resource "aws_iam_role_policy" "lambda_kms" {
  name = "${var.environment}-lambda-kms-policy"
  role = var.lambda_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}

# Policy for VPC access (if Lambda is in VPC)
resource "aws_iam_role_policy" "lambda_vpc" {
  count = var.enable_vpc ? 1 : 0
  name  = "${var.environment}-lambda-vpc-policy"
  role  = var.lambda_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.environment}-health-check-function"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.environment}-health-check-logs"
  }
}

# Lambda function
resource "aws_lambda_function" "health_check" {
  filename         = var.lambda_zip_path
  function_name    = "${var.environment}-health-check-function"
  role             = var.lambda_role_arn
  handler          = "handler.lambda_handler"
  source_code_hash = var.lambda_source_hash
  runtime          = "python3.11"
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = merge(
      {
        DYNAMODB_TABLE = var.dynamodb_table_name
        ENVIRONMENT    = var.environment
      },
      var.enable_api_key ? { API_KEY = random_password.api_key[0].result } : {}
    )
  }

  dynamic "vpc_config" {
    for_each = var.enable_vpc ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [var.security_group_id]
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_logging,
    aws_iam_role_policy.lambda_dynamodb,
    aws_cloudwatch_log_group.lambda
  ]

  tags = {
    Name = "${var.environment}-health-check-function"
  }
}

