terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# Data source to get the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 instances to access AWS services
resource "aws_iam_role" "ec2_role" {
  name = "${var.name_prefix}-ecommerce-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.name_prefix}-ecommerce-ec2-role"
    Environment = var.environment
  }
}

# IAM Policy for CloudWatch Logs and Systems Manager
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.name_prefix}-ecommerce-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:AcknowledgeMessage",
          "ssmmessages:GetEndpoint",
          "ssmmessages:GetMessages",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::aws-windows-downloads-aws-io/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name_prefix}-ecommerce-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance(s)
resource "aws_instance" "app_server" {
  count                    = var.instance_count
  ami                      = data.aws_ami.ubuntu.id
  instance_type            = var.instance_type
  subnet_id                = aws_subnet.public.id
  vpc_security_group_ids   = [aws_security_group.backend_services.id, aws_security_group.frontend.id]
  iam_instance_profile     = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  # Read and execute the user data script
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    AWS_REGION                = var.aws_region
    ECR_REGISTRY              = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
    ECR_REPOSITORY            = var.ecr_repository_name
    FRONTEND_IMAGE_TAG        = var.frontend_image_tag
    USER_SERVICE_IMAGE_TAG    = var.user_service_image_tag
    PRODUCT_SERVICE_IMAGE_TAG = var.product_service_image_tag
    CART_SERVICE_IMAGE_TAG    = var.cart_service_image_tag
    ORDER_SERVICE_IMAGE_TAG   = var.order_service_image_tag
  }))

  # CloudWatch monitoring
  monitoring = true

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.name_prefix}-ecommerce-root-volume"
    }
  }

  # Additional EBS volume for Docker data (optional)
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.name_prefix}-ecommerce-docker-volume"
    }
  }

  tags = {
    Name        = "${var.instance_name}-${count.index + 1}"
    Environment = var.environment
    Application = "ecommerce"
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_iam_role_policy.ec2_policy
  ]
}

# Elastic IP for the first instance (for static IP)
resource "aws_eip" "app_server" {
  count    = var.instance_count
  instance = aws_instance.app_server[count.index].id
  domain   = "vpc"

  tags = {
    Name        = "${var.name_prefix}-ecommerce-eip-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.name_prefix}-ecommerce-app"
  retention_in_days = 7

  tags = {
    Name        = "${var.name_prefix}-ecommerce-app-logs"
    Environment = var.environment
  }
}

# CloudWatch Alarm for high CPU usage
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count               = var.instance_count
  alarm_name          = "${var.name_prefix}-ecommerce-cpu-utilization-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when instance CPU exceeds 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.app_server[count.index].id
  }

  tags = {
    Name        = "${var.name_prefix}-ecommerce-cpu-alarm-${count.index + 1}"
    Environment = var.environment
  }
}

# CloudWatch Alarm for instance status checks
resource "aws_cloudwatch_metric_alarm" "instance_health" {
  count               = var.instance_count
  alarm_name          = "${var.name_prefix}-ecommerce-instance-health-${count.index + 1}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when instance health check fails"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.app_server[count.index].id
  }

  tags = {
    Name        = "${var.name_prefix}-ecommerce-health-alarm-${count.index + 1}"
    Environment = var.environment
  }
}
