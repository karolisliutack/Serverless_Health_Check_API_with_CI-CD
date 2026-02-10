# IAM Role for Lambda function execution
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

# Policy for CloudWatch Logs - least privilege
resource "aws_iam_role_policy" "lambda_logging" {
  name = "${var.environment}-lambda-logging-policy"
  role = aws_iam_role.lambda_execution.id

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

# Policy for DynamoDB - least privilege (specific table only)
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.environment}-lambda-dynamodb-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.requests.arn
      }
    ]
  })
}

# Policy for KMS - allow Lambda to use the DynamoDB encryption key
resource "aws_iam_role_policy" "lambda_kms" {
  name = "${var.environment}-lambda-kms-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.dynamodb.arn
      }
    ]
  })
}

# Policy for VPC access (if Lambda is in VPC)
resource "aws_iam_role_policy" "lambda_vpc" {
  count = var.enable_vpc ? 1 : 0
  name  = "${var.environment}-lambda-vpc-policy"
  role  = aws_iam_role.lambda_execution.id

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
  retention_in_days = 14

  tags = {
    Name = "${var.environment}-health-check-logs"
  }
}
