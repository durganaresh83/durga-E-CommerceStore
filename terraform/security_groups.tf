# Security Group for ALB / Frontend Access
resource "aws_security_group" "frontend" {
  name        = "${var.name_prefix}-ecommerce-frontend-sg"
  description = "Security group for frontend access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere on port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name_prefix}-ecommerce-frontend-sg"
    Environment = var.environment
  }
}

# Security Group for Internal Services
resource "aws_security_group" "backend_services" {
  name        = "${var.name_prefix}-ecommerce-backend-sg"
  description = "Security group for backend services"
  vpc_id      = aws_vpc.main.id

  # Allow SSH from anywhere (consider restricting this)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Frontend access to services
  ingress {
    description = "Frontend port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # User Service
  ingress {
    description = "User Service port 3001"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Product Service
  ingress {
    description = "Product Service port 3002"
    from_port   = 3002
    to_port     = 3002
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Cart Service
  ingress {
    description = "Cart Service port 3003"
    from_port   = 3003
    to_port     = 3003
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Order Service
  ingress {
    description = "Order Service port 3004"
    from_port   = 3004
    to_port     = 3004
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic for Docker operations
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name_prefix}-ecommerce-backend-sg"
    Environment = var.environment
  }
}

# Allow frontend SG to access backend SG services
resource "aws_security_group_rule" "frontend_to_backend" {
  type                     = "ingress"
  from_port                = 3001
  to_port                  = 3004
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend.id
  security_group_id        = aws_security_group.backend_services.id
  description              = "Allow frontend to access backend services"
}
