# S3 Backend for Terraform state
# Configuration values are provided via -backend-config flags in CI/CD pipeline
# This allows different state files per environment (staging/prod)
terraform {
  backend "s3" {}
}
