# Backend configuration for Terraform state
# Uncomment and configure when S3 bucket and DynamoDB table are created
#
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "health-check-api/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
#
# To use remote state:
# 1. Create an S3 bucket for state storage
# 2. Create a DynamoDB table for state locking (partition key: LockID)
# 3. Uncomment the backend block above and update values
# 4. Run: terraform init -migrate-state
