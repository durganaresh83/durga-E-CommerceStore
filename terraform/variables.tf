variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "durga"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "instance_name" {
  description = "Name tag for EC2 instances"
  type        = string
  default     = "durga-ecommerce-app-server"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_account_id" {
  description = "AWS Account ID for ECR repository"
  type        = string
  sensitive   = true
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "durga-pubic-repo"
}

variable "frontend_image_tag" {
  description = "Frontend Docker image tag"
  type        = string
  default     = "durga-ecommerce-frontend-latest"
}

variable "user_service_image_tag" {
  description = "User service Docker image tag"
  type        = string
  default     = "durga-ecommerce-user-service-latest"
}

variable "product_service_image_tag" {
  description = "Product service Docker image tag"
  type        = string
  default     = "durga-ecommerce-product-service-latest"
}

variable "cart_service_image_tag" {
  description = "Cart service Docker image tag"
  type        = string
  default     = "durga-ecommerce-cart-service-latest"
}

variable "order_service_image_tag" {
  description = "Order service Docker image tag"
  type        = string
  default     = "durga-ecommerce-order-service-latest"
}
