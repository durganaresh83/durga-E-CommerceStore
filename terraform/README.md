# E-Commerce Microservices - Terraform Infrastructure as Code

This Terraform configuration provisions AWS infrastructure to host the e-commerce microservices application.

## Overview

The infrastructure includes:
- **VPC** with public subnet and Internet Gateway
- **EC2 instances** (configurable count) with Docker and Docker Compose
- **Security Groups** for frontend access and internal service communication
- **IAM roles and policies** for EC2 instances
- **CloudWatch monitoring** with alarms and log groups
- **Elastic IPs** for static public addresses
- **EBS volumes** with encryption enabled

## Architecture

```
┌─────────────────────────────────────────────┐
│           VPC (10.0.0.0/16)                 │
│  ┌──────────────────────────────────────┐  │
│  │  Public Subnet (10.0.1.0/24)         │  │
│  │  ┌──────────────────────────────┐    │  │
│  │  │  EC2 Instance - Ubuntu 22.04 │    │  │
│  │  │  - Docker Engine             │    │  │
│  │  │  - Docker Compose            │    │  │
│  │  │  ┌────────────────────────┐  │    │  │
│  │  │  │ Frontend (port 3000)   │  │    │  │
│  │  │  ├────────────────────────┤  │    │  │
│  │  │  │ User Service (3001)    │  │    │  │
│  │  │  │ Product Service (3002) │  │    │  │
│  │  │  │ Cart Service (3003)    │  │    │  │
│  │  │  │ Order Service (3004)   │  │    │  │
│  │  │  └────────────────────────┘  │    │  │
│  │  │                              │    │  │
│  │  └──────────────────────────────┘    │  │
│  │                                      │  │
│  │  Security Groups:                    │  │
│  │  - Frontend SG (HTTP 80, 3000)       │  │
│  │  - Backend SG (SSH, Int. comms)      │  │
│  └──────────────────────────────────────┘  │
│                                             │
│         Internet Gateway                    │
│         (Route to 0.0.0.0/0)               │
└─────────────────────────────────────────────┘
```

## Files

- `main.tf` - EC2 instances, IAM roles, CloudWatch resources
- `vpc.tf` - VPC, subnets, Internet Gateway, route tables
- `security_groups.tf` - Security group definitions
- `variables.tf` - Input variables and their defaults
- `outputs.tf` - Output values (IPs, URLs, etc.)
- `user_data.sh` - Bootstrap script (Docker installation, container setup)
- `terraform.tfvars.example` - Example variable file
- `.gitignore` - Git ignore patterns

## Prerequisites

1. **AWS Account** with appropriate IAM permissions
2. **Terraform** installed (version >= 1.0)
3. **AWS CLI** configured with credentials
4. **DockerHub Account** for pulling images (set docker_hub_user and docker_hub_pass)
5. **SSH Key Pair** created in your AWS region

## Setup Instructions

### 1. Clone/Copy Terraform Configuration

```bash
cd terraform
```

### 2. Create terraform.tfvars

Copy the example file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and add:
```hcl
aws_region      = "us-east-1"  # Change to your preferred region
docker_hub_user = "your-dockerhub-username"
docker_hub_pass = "your-dockerhub-password"
instance_count  = 1
instance_type   = "t2.medium"
```

⚠️ **Security Warning**: Do NOT commit `terraform.tfvars` with actual credentials to version control.

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Apply Configuration

```bash
terraform apply
```

Review the changes and type `yes` to confirm.

## Post-Deployment

### 1. Get Access Information

After deployment, Terraform outputs the access URLs:

```bash
terraform output application_access_info
```

Example output:
```json
{
  "cart_service_url" = "http://54.123.45.67:3003"
  "frontend_url" = "http://54.123.45.67:3000"
  "order_service_url" = "http://54.123.45.67:3004"
  "product_service_url" = "http://54.123.45.67:3002"
  "user_service_url" = "http://54.123.45.67:3001"
}
```

### 2. SSH into Instance

```bash
terraform output ssh_access
# Example: ssh -i <your-key.pem> ubuntu@54.123.45.67
```

### 3. Check Container Status

```bash
ssh -i <your-key.pem> ubuntu@<instance-ip>
docker ps
docker-compose logs -f
```

### 4. View User Data Logs

User data script logs are available at `/var/log/user-data.log` on the instance:

```bash
ssh -i <your-key.pem> ubuntu@<instance-ip>
tail -f /var/log/user-data.log
```

## Monitoring

### CloudWatch Logs

Logs are sent to `/aws/ec2/ecommerce-app` log group in CloudWatch.

```bash
aws logs tail /aws/ec2/ecommerce-app --follow
```

### CloudWatch Metrics

- **CPU Utilization** - Alarms trigger when CPU > 80% for 10 minutes
- **Instance Health** - Alarms trigger when status checks fail

View in AWS Console:
- CloudWatch → Alarms

## Scaling

### Increase Instance Count

Modify `terraform.tfvars`:
```hcl
instance_count = 2  # or higher
```

Apply changes:
```bash
terraform apply
```

### Change Instance Type

Modify `terraform.tfvars`:
```hcl
instance_type = "t2.large"  # or other instance types
```

Apply changes:
```bash
terraform apply
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Review the resources to be destroyed and type `yes` to confirm.

## Security Considerations

1. **Change SSH Port Range** - Modify security groups in `security_groups.tf` to restrict SSH access:
   ```hcl
   cidr_blocks = ["YOUR_IP/32"]  # Instead of "0.0.0.0/0"
   ```

2. **Credentials Management** - Use AWS Secrets Manager or Parameter Store:
   ```bash
   # Store credentials in AWS Secrets Manager
   aws secretsmanager create-secret --name docker-hub --secret-string '{"username":"...","password":"..."}'
   ```

3. **Enable VPC Flow Logs** - Add to `vpc.tf`:
   ```hcl
   resource "aws_flow_log" "main" {
     iam_role_arn = aws_iam_role.vpc_flow_log_role.arn
     log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
     traffic_type = "ALL"
     vpc_id = aws_vpc.main.id
   }
   ```

4. **Use HTTPS** - Set up an Application Load Balancer with SSL certificates
5. **Database Security** - Use AWS RDS with security groups instead of local MongoDB

## Troubleshooting

### Containers Not Running

1. SSH into instance and check logs:
   ```bash
   cat /var/log/user-data.log
   docker logs <container-name>
   docker-compose logs
   ```

2. Verify Docker images were pulled:
   ```bash
   docker images
   ```

3. Check security group rules allow traffic on ports 3000-3004

### User Data Script Failed

1. Check user data execution:
   ```bash
   tail -100 /var/log/cloud-init-output.log
   tail -f /var/log/user-data.log
   ```

2. Verify Docker Hub credentials are correct in `terraform.tfvars`

3. Ensure the instance has internet access to pull images

### Terraform State Issues

1. Check state file:
   ```bash
   terraform show
   ```

2. Refresh state:
   ```bash
   terraform refresh
   ```

3. If locked, remove lock file:
   ```bash
   rm -rf .terraform.tfstate.lock.hcl
   ```

## Advanced Configuration

### Using Multiple Availability Zones

Add to `vpc.tf`:
```hcl
resource "aws_subnet" "public_az2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}
```

### Adding Application Load Balancer

Create `alb.tf`:
```hcl
resource "aws_lb" "main" {
  load_balancer_type = "application"
  subnets = [aws_subnet.public.id]
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "app" {
  port = 3000
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
}
```

### Adding Auto Scaling

Create `asg.tf`:
```hcl
resource "aws_launch_template" "app" {
  image_id = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  user_data = base64encode(file("${path.module}/user_data.sh"))
}

resource "aws_autoscaling_group" "app" {
  launch_template {
    id = aws_launch_template.app.id
    version = "$Latest"
  }
  min_size = 1
  max_size = 5
  desired_capacity = 2
  vpc_zone_identifier = [aws_subnet.public.id]
}
```

## Costs Estimation

Assuming us-east-1 region with 1x t2.medium instance:

| Service | Monthly Cost |
|---------|-------------|
| t2.medium EC2 (Linux) | ~$30 |
| EBS Storage (30GB + 50GB) | ~$9 |
| Elastic IP | Free* |
| Data Transfer | ~$1 |
| CloudWatch | ~$0.50 |
| **Total** | **~$40-50/month** |

*Free if associated with running instance

## Support

For issues or questions:
1. Check CloudWatch logs
2. Review Terraform state: `terraform show`
3. Check EC2 instance system logs in AWS Console
4. Review security group rules and network ACLs

## License

This Terraform configuration is part of the E-Commerce Microservices project.
