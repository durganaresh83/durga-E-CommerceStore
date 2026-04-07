# E-Commerce Store Terraform Deployment - Troubleshooting Guide

## Current Deployment Status

### ✓ Completed Tasks
- [x] All Docker images built successfully (frontend + 4 backend services)
- [x] Docker Compose verified locally with MongoDB
- [x] All backend services tested and working (ports 3001-3004)
- [x] Frontend verified on port 3000
- [x] AWS VPC infrastructure created (VPC ID: vpc-03be81205d96c5bed)
- [x] AWS Internet Gateway created (IGW ID: igw-077d53fe47628d6cb)
- [x] AWS Public Subnet created (Subnet: subnet-0fa722cb548c42145)
- [x] AWS Security Groups created properly (Frontend & Backend)
- [x] AWS IAM role and policies configured
- [x] CloudWatch log group created
- [x] All Terraform configuration files validated

### ⚠️ Blocking Issue: IAM Permissions
**Status**: Cannot create EC2 instances due to missing IAM permissions

**Error**:
```
UnauthorizedOperation: You are not authorized to perform this operation.
User: arn:aws:iam::975050024946:user/durganareshpotta83@gmail.com 
is not authorized to perform: ec2:RunInstances on resource: 
arn:aws:ec2:eu-west-2:975050024946:instance/*
```

**Root Cause**: The AWS IAM user is missing EC2 instance launch permissions

## Resolution Steps

### Step 1: Verify Your AWS Credentials
```bash
# Check current AWS identity
aws sts get-caller-identity
```

Expected output should show your account ID: `975050024946`

### Step 2: Check Current IAM User Permissions
```bash
# List attached policies
aws iam list-attached-user-policies --user-name durganareshpotta83@gmail.com

# List inline policies
aws iam list-user-policies --user-name durganareshpotta83@gmail.com

# Get specific policy details
aws iam get-user-policy --user-name durganareshpotta83@gmail.com --policy-name <PolicyName>
```

### Step 3: Grant Required Permissions

**Option A: If you are an AWS Administrator**
1. See `IAM_POLICY_REQUIRED.md` in this directory
2. Apply the policy document provided

**Option B: If you need to request permissions**
1. Contact your AWS Administrator
2. Share `IAM_POLICY_REQUIRED.md` with them
3. Ask them to attach the policy to your user: `durganareshpotta83@gmail.com`

### Step 4: Verify Permission Grant**
```bash
# Test EC2 permissions
aws ec2 describe-instances --region eu-west-2

# If you can see existing instances, permissions are working
```

### Step 5: Retry Terraform Deployment
```bash
cd terraform

# Clean up the failed resources (optional)
terraform destroy -auto-approve

# Or continue with remaining resources
terraform apply -auto-approve
```

## Alternative Approaches

### Using AWS CloudFormation (If Terraform is Blocked)
If the IAM user permanently cannot get EC2 launch permissions, you can use CloudFormation instead:

```bash
# Create CloudFormation stack
aws cloudformation create-stack \
  --stack-name durga-ecommerce \
  --template-body file://cloudformation-template.yml \
  --parameters ... \
  --region eu-west-2
```

### Using AWS SSO/Elevated Credentials
If your organization uses AWS SSO:
```bash
# Login with SSO
aws sso login --profile your-profile

# Set AWS_PROFILE for Terraform
export AWS_PROFILE=your-sso-profile

# Run Terraform
terraform apply -auto-approve
```

### Manual EC2 Launch (Last Resort)
If permissions cannot be granted, you can manually:
1. Launch an EC2 instance in AWS console with the specified configuration
2. Manually install Docker and Docker Compose
3. Pull images from ECR and run docker-compose
4. Map the instance to the Terraform outputs

## Pre-Deployment Checklist

- [ ] AWS Account ID Verified: `975050024946`
- [ ] Region Confirmed: `eu-west-2` (London)
- [ ] IAM User: `durganareshpotta83@gmail.com`
- [ ] EC2:RunInstances permission verified
- [ ] AWS CLI configured correctly
- [ ] Terraform initialized (`terraform init` completed)
- [ ] Terraform plan generated successfully
- [ ] Security group rules verified
- [ ] Docker images ready for ECR push
- [ ] ECR repository exists: `durga-pubic-repo`

## Deployment After Permission Fix

Once permissions are granted:

```bash
# Navigate to terraform directory
cd terraform

# Apply the remaining infrastructure
terraform apply -auto-approve

# Monitor progress
watch 'terraform show | grep -E "id|public_ip"'

# Get the final outputs
terraform output

# You should see:
# - public_ip: The Elastic IP for frontend access
# - application_urls: All service endpoints
# - deployment_summary: Complete deployment details
```

## Services Access After Deployment

Once EC2 is deployed, services will be accessible at:
- **Frontend**: `http://<PUBLIC_IP>:3000`
- **User Service**: `http://<PUBLIC_IP>:3001`
- **Product Service**: `http://<PUBLIC_IP>:3002`
- **Cart Service**: `http://<PUBLIC_IP>:3003`
- **Order Service**: `http://<PUBLIC_IP>:3004`

(Replace `<PUBLIC_IP>` with the Elastic IP shown in terraform output)

## SSH Access to EC2
```bash
# SSH key should be in ~/aws-keys/ or wherever you saved it
ssh -i ~/aws-keys/durga-key.pem ubuntu@<PUBLIC_IP>

# Install Docker (already done via user-data):
sudo docker ps

# View logs:
sudo docker-compose logs -f
```

## Troubleshooting Commands

```bash
# See detailed Terraform state
terraform state show

# List all Terraform resources
terraform state list

# Refresh Terraform state
terraform refresh

# Initialize fresh Terraform (WARNING: backs up current state)
terraform init -reconfigure

# Debug Terraform execution
TF_LOG=DEBUG terraform apply -auto-approve

# Check AWS CLI configuration
aws configure list

# Verify Terraform AWS provider configuration
terraform providers
```

## Common Issues and Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| `UnauthorizedOperation: ec2:RunInstances` | Missing IAM permission | See IAM_POLICY_REQUIRED.md |
| `Duplicate Security Group rule` | Duplicate ingress rules | Already fixed in security_groups.tf |
| `InvalidSubnet.Malformed` | VPC/Subnet mismatch | VPC already created and linked |
| `ResourceNotFound` | Destroyed resources referenced | Run terraform refresh |
| `ValidationError` | Terraform syntax error | Run terraform validate |

## Contact & Support

- **AWS Account ID**: 975050024946
- **AWS Region**: eu-west-2 (London)
- **Application Type**: E-Commerce Store (Microservices)
- **Infrastructure**: Terraform-managed
- **Container Platform**: Docker + Docker Compose on EC2

For additional help, contact your AWS Administrator with this document.
