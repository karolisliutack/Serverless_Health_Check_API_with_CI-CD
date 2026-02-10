# DynamoDB Module - Creates DynamoDB table with KMS encryption

# KMS Key for DynamoDB encryption (Customer Managed Key)
resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for ${var.environment}-requests-db DynamoDB table encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow DynamoDB to use the key"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda to use the key"
        Effect = "Allow"
        Principal = {
          AWS = var.lambda_role_arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "${var.environment}-dynamodb-kms-key"
    Project = "health-check-api"
  }
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.environment}-requests-db-key"
  target_key_id = aws_kms_key.dynamodb.key_id
}

# DynamoDB Table for storing health check requests
resource "aws_dynamodb_table" "requests" {
  name           = "${var.environment}-requests-db"
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.environment}-requests-db"
  }
}
