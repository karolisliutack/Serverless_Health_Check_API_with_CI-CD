# VPC for Lambda function (bonus requirement - Lambda in its own VPC)
resource "aws_vpc" "lambda" {
  count      = var.enable_vpc ? 1 : 0
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-lambda-vpc"
  }
}

# Private subnets for Lambda (2 AZs for high availability)
resource "aws_subnet" "lambda_private" {
  count             = var.enable_vpc ? 2 : 0
  vpc_id            = aws_vpc.lambda[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.environment}-lambda-private-${count.index + 1}"
  }
}

# Security group for Lambda
resource "aws_security_group" "lambda" {
  count       = var.enable_vpc ? 1 : 0
  name        = "${var.environment}-lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.lambda[0].id

  # Outbound traffic to AWS services (DynamoDB, CloudWatch)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound for AWS services"
  }

  tags = {
    Name = "${var.environment}-lambda-sg"
  }
}

# VPC Endpoint for DynamoDB (keeps traffic within AWS network)
resource "aws_vpc_endpoint" "dynamodb" {
  count           = var.enable_vpc ? 1 : 0
  vpc_id          = aws_vpc.lambda[0].id
  service_name    = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  route_table_ids = [aws_route_table.lambda_private[0].id]

  tags = {
    Name = "${var.environment}-dynamodb-endpoint"
  }
}

# VPC Endpoint for KMS (required for Lambda to decrypt environment variables)
resource "aws_vpc_endpoint" "kms" {
  count               = var.enable_vpc ? 1 : 0
  vpc_id              = aws_vpc.lambda[0].id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.lambda_private[*].id
  security_group_ids  = [aws_security_group.lambda[0].id]
  private_dns_enabled = true

  tags = {
    Name = "${var.environment}-kms-endpoint"
  }
}

# Route table for private subnets
resource "aws_route_table" "lambda_private" {
  count  = var.enable_vpc ? 1 : 0
  vpc_id = aws_vpc.lambda[0].id

  tags = {
    Name = "${var.environment}-lambda-private-rt"
  }
}

# Associate route table with private subnets
resource "aws_route_table_association" "lambda_private" {
  count          = var.enable_vpc ? 2 : 0
  subnet_id      = aws_subnet.lambda_private[count.index].id
  route_table_id = aws_route_table.lambda_private[0].id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
