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

### Required GitHub Secrets
Configure the following secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name | Description |
|-------------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key for deployment |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key |

### Required GitHub Environments
Create the following environments in your repository (`Settings > Environments`):

- **staging** - Automatic deployment on merge to main
- **production** - Configure with required reviewers for manual approval

### Local Development
- Terraform >= 1.0
- Python 3.11
- AWS CLI configured with credentials

## Project Structure

```
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI/CD pipeline
├── lambda/
│   ├── handler.py              # Lambda function code
│   └── requirements.txt        # Python dependencies
├── terraform/
│   ├── api_gateway.tf          # API Gateway configuration
│   ├── data.tf                 # AWS data sources
│   ├── dynamodb.tf             # DynamoDB table with KMS encryption
│   ├── iam.tf                  # IAM roles and policies
│   ├── lambda.tf               # Lambda function configuration
│   ├── outputs.tf              # Terraform outputs
│   ├── provider.tf             # AWS provider configuration
│   ├── variables.tf            # Variable definitions
│   ├── vpc.tf                  # VPC for Lambda isolation
│   ├── staging.tfvars          # Staging environment values
│   └── prod.tfvars             # Production environment values
└── README.md
```

## CI/CD Pipeline

### Pipeline Stages

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

### Deploy to Staging

**Option 1: Via GitHub Actions (Recommended)**
1. Push changes to the `main` branch or merge a PR
2. The pipeline automatically deploys to staging after security scans pass

**Option 2: Manual Trigger**
1. Go to Actions tab in GitHub
2. Select "Deploy Infrastructure" workflow
3. Click "Run workflow"
4. Select `staging` environment
5. Click "Run workflow"

**Option 3: Local Deployment**
```bash
cd terraform
terraform init
terraform apply -var-file="staging.tfvars"
```

### Deploy to Production

1. Ensure staging deployment is successful
2. Go to the running workflow in GitHub Actions
3. The production job will wait for approval
4. Click "Review deployments"
5. Select "production" environment and approve

## Testing the API

### GET Request
```bash
curl -X GET https://<api-id>.execute-api.us-east-1.amazonaws.com/health
```

### POST Request (with required payload)
```bash
curl -X POST https://<api-id>.execute-api.us-east-1.amazonaws.com/health \
  -H "Content-Type: application/json" \
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

## Security Features

### Encryption
- **DynamoDB**: Server-Side Encryption with Customer Managed Key (CMK)
- **KMS**: Key rotation enabled

### Network Security
- **Lambda VPC**: Function runs in isolated VPC with private subnets
- **VPC Endpoints**: DynamoDB access via VPC endpoint (traffic stays in AWS)
- **Security Groups**: Minimal egress rules (HTTPS only)

### API Security
- **Throttling**: Rate limiting to prevent DDoS attacks
- **Input Validation**: Lambda validates required `payload` key on POST requests

### IAM Security
- **Least Privilege**: All IAM policies scoped to specific resources
- **No Wildcards**: Except where AWS requires (EC2 network interfaces for VPC)

## Design Choices

### Multi-Environment Support
- Separate `.tfvars` files for staging and production
- Environment prefix on all resource names (`staging-*`, `prod-*`)
- Different capacity settings per environment

### VPC Isolation (Bonus)
- Lambda runs in private subnets for additional security
- VPC endpoints eliminate need for NAT Gateway
- Security group limits outbound traffic to HTTPS only

### Customer Managed Keys (Bonus)
- KMS CMK for DynamoDB encryption instead of AWS managed keys
- Key rotation enabled for compliance

### Modular Terraform Structure
- Separate files for each resource type
- Easy to navigate and maintain
- Clear separation of concerns

## Assumptions

1. Single region deployment (us-east-1) - can be changed via variables
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
