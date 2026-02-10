# Data sources for referencing AWS account information
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
