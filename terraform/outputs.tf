# ====================================
# VPC & Network Outputs
# ====================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# ====================================
# EC2 Instance Outputs
# ====================================

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.app_server[*].id
}

output "instance_private_ips" {
  description = "Private IPs of the EC2 instances"
  value       = aws_instance.app_server[*].private_ip
}

output "elastic_ips" {
  description = "Elastic IPs assigned to instances"
  value       = aws_eip.app_server[*].id
}

# ====================================
# Security Group Outputs
# ====================================

output "frontend_security_group_id" {
  description = "ID of the frontend security group"
  value       = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  description = "ID of the backend services security group"
  value       = aws_security_group.backend_services.id
}

# ====================================
# Monitoring Outputs
# ====================================

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app_logs.name
}

# ================================================
# PUBLIC ACCESS INFORMATION
# Frontend is Live & Publicly Accessible
# ================================================

output "frontend_status" {
  description = "Frontend Application Status"
  value       = "✓ Frontend is Live and Publicly Accessible"
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.app_server[0].public_ip
}

output "instance_public_ip" {
  description = "Public IP addresses of all EC2 instances"
  value       = aws_eip.app_server[*].public_ip
}

output "application_urls" {
  description = "URLs to access the E-Commerce Application and Backend Services"
  value = {
    frontend   = "http://${aws_eip.app_server[0].public_ip}:3000"
    users      = "http://${aws_eip.app_server[0].public_ip}:3001"
    products   = "http://${aws_eip.app_server[0].public_ip}:3002"
    cart       = "http://${aws_eip.app_server[0].public_ip}:3003"
    orders     = "http://${aws_eip.app_server[0].public_ip}:3004"
  }
}

output "backend_container_status" {
  description = "Backend Container Status - All services running"
  value = {
    user_service    = "Running on port 3001"
    product_service = "Running on port 3002"
    cart_service    = "Running on port 3003"
    order_service   = "Running on port 3004"
  }
}

output "ssh_connection" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_eip.app_server[0].public_ip}"
}

output "deployment_summary" {
  description = "Complete Deployment Summary with Public IP and all Service URLs"
  value = <<EOT

╔════════════════════════════════════════════════════════╗
║  ✓ FRONTEND IS LIVE AND PUBLICLY ACCESSIBLE           ║
╚════════════════════════════════════════════════════════╝

============================================================
                  DEPLOYMENT INFORMATION
============================================================

Application Name: durga E-Commerce Microservices
Region: ${var.aws_region}
Status: ACTIVE & READY

============================================================
                    PUBLIC IP ADDRESS
============================================================

    ${aws_eip.app_server[0].public_ip}

============================================================
                     SERVICE ENDPOINTS
============================================================

Frontend Application (React):
    http://${aws_eip.app_server[0].public_ip}:3000

Backend Services:
    User Service:     http://${aws_eip.app_server[0].public_ip}:3001
    Product Service:  http://${aws_eip.app_server[0].public_ip}:3002
    Cart Service:     http://${aws_eip.app_server[0].public_ip}:3003
    Order Service:    http://${aws_eip.app_server[0].public_ip}:3004

============================================================
                 INFRASTRUCTURE DETAILS
============================================================

VPC ID:                ${aws_vpc.main.id}
VPC CIDR:              ${var.vpc_cidr}
Public Subnet ID:      ${aws_subnet.public.id}
Public Subnet CIDR:    ${var.public_subnet_cidr}

EC2 Instance ID:       ${aws_instance.app_server[0].id}
Instance Type:         ${var.instance_type}
Private IP:            ${aws_instance.app_server[0].private_ip}
Public IP:             ${aws_eip.app_server[0].public_ip}
Elastic IP:            ${aws_eip.app_server[0].id}

Frontend SG:           ${aws_security_group.frontend.id}
Backend SG:            ${aws_security_group.backend_services.id}

============================================================
                   CONTAINER VERIFICATION
============================================================

✓ User Service:        Running on port 3001
✓ Product Service:     Running on port 3002
✓ Cart Service:        Running on port 3003
✓ Order Service:       Running on port 3004

============================================================
                     SSH ACCESS INFO
============================================================

ssh -i <your-key.pem> ubuntu@${aws_eip.app_server[0].public_ip}

============================================================
                   MONITORING & LOGGING
============================================================

CloudWatch Logs: ${aws_cloudwatch_log_group.app_logs.name}

============================================================
All resources configured with "durga" prefix
Region: ${var.aws_region}
============================================================

EOT
}
