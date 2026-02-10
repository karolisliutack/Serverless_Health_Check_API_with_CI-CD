# VPC Module - Creates VPC infrastructure for Lambda isolation

resource "aws_vpc" "main" {
  count      = var.enabled ? 1 : 0
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-lambda-vpc"
  }
}

# Private subnets for Lambda (2 AZs for high availability)
resource "aws_subnet" "private" {
  count             = var.enabled ? 2 : 0
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.environment}-lambda-private-${count.index + 1}"
  }
}

# Security group for Lambda
resource "aws_security_group" "lambda" {
  count       = var.enabled ? 1 : 0
  name        = "${var.environment}-lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.main[0].id

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

# Route table for private subnets
resource "aws_route_table" "private" {
  count  = var.enabled ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${var.environment}-lambda-private-rt"
  }
}

# Associate route table with private subnets
resource "aws_route_table_association" "private" {
  count          = var.enabled ? 2 : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# VPC Endpoint for DynamoDB (keeps traffic within AWS network)
resource "aws_vpc_endpoint" "dynamodb" {
  count           = var.enabled ? 1 : 0
  vpc_id          = aws_vpc.main[0].id
  service_name    = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = [aws_route_table.private[0].id]

  tags = {
    Name = "${var.environment}-dynamodb-endpoint"
  }
}

# VPC Endpoint for KMS (required for Lambda to decrypt environment variables)
resource "aws_vpc_endpoint" "kms" {
  count               = var.enabled ? 1 : 0
  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.lambda[0].id]
  private_dns_enabled = true

  tags = {
    Name = "${var.environment}-kms-endpoint"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
