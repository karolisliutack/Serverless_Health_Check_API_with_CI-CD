# Serverless Health Check API

A serverless health check API built on AWS using Terraform, featuring a Lambda function that logs requests and stores them in DynamoDB.

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client    │────▶│ API Gateway │────▶│   Lambda    │────▶│  DynamoDB   │
│             │     │ (Throttled) │     │  (in VPC)   │     │ (Encrypted) │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                           │                   │
                           ▼                   ▼
                    ┌─────────────┐     ┌─────────────┐
                    │ CloudWatch  │     │ CloudWatch  │
                    │   Logs      │     │    Logs     │
                    └─────────────┘     └─────────────┘
```

## Prerequisites

### AWS Account Setup
- AWS Account with appropriate permissions
- AWS CLI installed and configured

### Bootstrap: Create Terraform State Backend

Before running the CI/CD pipeline, you must create the S3 bucket and DynamoDB table for Terraform state:

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

This creates:
- S3 bucket for state storage (encrypted, versioned)
- DynamoDB table for state locking

Note the output values - you'll need them for GitHub secrets.

### Required GitHub Secrets

Configure the following secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name | Description |
|-------------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key for deployment |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key |
| `AWS_REGION` | AWS region (e.g., eu-central-1) |
| `TF_STATE_BUCKET` | S3 bucket name from bootstrap output |
| `TF_LOCK_TABLE` | DynamoDB table name from bootstrap output |

### Required GitHub Environments

Create the following environments in your repository (`Settings > Environments`):

- **staging** - Automatic deployment on merge to main
- **production** - Configure with **required reviewers** for manual approval

### Local Development
- Terraform >= 1.0
- Python 3.11
- AWS CLI configured with credentials

## Project Structure

```
├── .github/
│   └── workflows/
│       └── deploy.yml              # CI/CD pipeline
├── lambda/
│   ├── handler.py                  # Lambda function code
│   └── requirements.txt            # Python dependencies
├── terraform/
│   ├── bootstrap/                  # Bootstrap for state backend
│   │   ├── main.tf
│   │   └── deployment-policy.json  # IAM policy for deployer
│   ├── modules/                    # Reusable Terraform modules
│   │   ├── api_gateway/            # API Gateway module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── dynamodb/               # DynamoDB + KMS module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── lambda/                 # Lambda function module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── vpc/                    # VPC module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── main.tf                     # Main config using modules
│   ├── backend.tf                  # S3 backend configuration
│   ├── outputs.tf                  # Terraform outputs
│   ├── provider.tf                 # AWS provider configuration
│   ├── variables.tf                # Variable definitions
│   ├── staging.tfvars              # Staging environment values
│   └── prod.tfvars                 # Production environment values
└── README.md
```

## CI/CD Pipeline

### Pipeline Stages

```
┌──────────────────┐     ┌──────────────────┐
│ Dependency Scan  │     │  Security Scan   │
│   (pip-audit)    │     │ (tfsec+checkov)  │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         └───────────┬────────────┘
                     ▼
         ┌──────────────────────┐
         │   Terraform Plan     │
         │  (staging + prod)    │
         └──────────┬───────────┘
                    ▼
         ┌──────────────────────┐
         │   Deploy Staging     │
         │    (automatic)       │
         └──────────┬───────────┘
                    ▼
         ┌──────────────────────┐
         │  Deploy Production   │
         │ (manual approval)    │
         └──────────────────────┘
```

1. **Dependency Scan** - Scans Lambda Python dependencies for vulnerabilities using `pip-audit`
2. **Security Scan** - Runs `tfsec` and `checkov` on Terraform code for IaC security issues
3. **Terraform Plan** - Generates execution plans for both staging and production
4. **Deploy Staging** - Automatically deploys to staging on merge to main
5. **Deploy Production** - Requires manual approval before deployment

### Pipeline Triggers

- **Push to main/master**: Runs full pipeline with automatic staging deployment
- **Pull Request**: Runs scans and plan only (no deployment)
- **Manual Trigger**: Select environment via workflow dispatch

## Deployment Instructions

### Step 1: Bootstrap (One-time Setup)

```bash
# Create state backend resources
cd terraform/bootstrap
terraform init
terraform apply

# Note the outputs:
# - state_bucket_name
# - dynamodb_table_name
```

### Step 2: Configure GitHub

1. Go to repository **Settings > Secrets and variables > Actions**
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` (e.g., `eu-central-1`)
   - `TF_STATE_BUCKET` (from bootstrap output)
   - `TF_LOCK_TABLE` (from bootstrap output)

3. Go to **Settings > Environments**
4. Create `staging` environment
5. Create `production` environment with **required reviewers**

### Step 3: Deploy to Staging

**Option 1: Via GitHub Actions (Recommended)**
1. Push changes to the `main` branch or merge a PR
2. The pipeline automatically deploys to staging after security scans pass

**Option 2: Manual Trigger**
1. Go to Actions tab in GitHub
2. Select "Deploy Infrastructure" workflow
3. Click "Run workflow"
4. Select `staging` environment
5. Click "Run workflow"

### Step 4: Deploy to Production

1. Ensure staging deployment is successful
2. Go to the running workflow in GitHub Actions
3. The production job will wait for approval
4. Click "Review deployments"
5. Select "production" environment and approve

## Testing the API

### Get API Key
After deployment, retrieve the API key from Terraform output:
```bash
cd terraform
terraform output -raw api_key
```

### GET Request (with API key)
```bash
curl -X GET https://<api-id>.execute-api.eu-central-1.amazonaws.com/health \
  -H "x-api-key: <your-api-key>"
```

### POST Request (with required payload and API key)
```bash
curl -X POST https://<api-id>.execute-api.eu-central-1.amazonaws.com/health \
  -H "Content-Type: application/json" \
  -H "x-api-key: <your-api-key>" \
  -d '{"payload": "test data"}'
```

### Expected Response
```json
{
  "status": "healthy",
  "message": "Request processed and saved.",
  "request_id": "uuid-generated-id"
}
```

### Error Response (missing payload on POST)
```json
{
  "status": "error",
  "message": "Missing required key: 'payload'"
}
```

### Error Response (missing or invalid API key)
```json
{
  "status": "error",
  "message": "Unauthorized: Invalid or missing API key"
}
```

## Security Features

### Encryption
- **DynamoDB**: Server-Side Encryption with Customer Managed Key (CMK)
- **KMS**: Key rotation enabled
- **Terraform State**: Encrypted in S3

### Network Security
- **Lambda VPC**: Function runs in isolated VPC with private subnets
- **VPC Endpoints**: DynamoDB access via VPC endpoint (traffic stays in AWS)
- **Security Groups**: Minimal egress rules (HTTPS only)

### API Security
- **API Key Authentication**: Requests must include valid `x-api-key` header
- **Throttling**: Rate limiting to prevent DDoS attacks (100 req/s staging, 500 req/s prod)
- **Input Validation**: Lambda validates required `payload` key on POST requests

### IAM Security
- **Least Privilege**: All IAM policies scoped to specific resources
- **No Wildcards**: Except where AWS requires (EC2 network interfaces for VPC)

### CI/CD Security
- **Dependency Scanning**: pip-audit checks for vulnerable packages
- **IaC Scanning**: tfsec and checkov validate Terraform security
- **Manual Approval**: Production requires human approval

## Design Choices

### Multi-Environment Support
- Separate `.tfvars` files for staging and production
- Separate Terraform state files per environment
- Environment prefix on all resource names (`staging-*`, `prod-*`)
- Different capacity settings per environment

### VPC Isolation (Bonus)
- Lambda runs in private subnets for additional security
- VPC endpoints eliminate need for NAT Gateway
- Security group limits outbound traffic to HTTPS only

### Customer Managed Keys (Bonus)
- KMS CMK for DynamoDB encryption instead of AWS managed keys
- Key rotation enabled for compliance

### Remote State Management
- S3 backend with encryption and versioning
- DynamoDB for state locking (prevents concurrent modifications)
- Separate state files per environment

## Assumptions

1. Single region deployment (eu-central-1) - configured in .tfvars files
2. Provisioned capacity for DynamoDB (can switch to on-demand if needed)
3. Python 3.11 runtime for Lambda
4. 14-day log retention for cost optimization

## Outputs

After deployment, Terraform outputs the following:

| Output | Description |
|--------|-------------|
| `api_endpoint` | Full URL for the /health endpoint |
| `lambda_function_arn` | ARN of the deployed Lambda function |
| `dynamodb_table_name` | Name of the DynamoDB table |
| `kms_key_arn` | ARN of the KMS encryption key |
| `vpc_id` | ID of the VPC (if enabled) |
