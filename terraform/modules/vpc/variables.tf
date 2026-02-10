variable "environment" {
  description = "Environment name (staging or prod)"
  type        = string
}

variable "enabled" {
  description = "Enable VPC creation"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_region" {
  description = "AWS region for VPC endpoints"
  type        = string
}
