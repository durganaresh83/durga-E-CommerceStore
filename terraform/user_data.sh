#!/bin/bash
set -e

# Log file for debugging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting EC2 user-data script..."
echo "==============================="

# Update system packages
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Docker
echo "Installing Docker..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker service
echo "Starting Docker service..."
systemctl enable docker
systemctl start docker

# Install docker-compose standalone
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

docker-compose --version

# Install AWS CLI v2
echo "Installing AWS CLI..."
apt-get install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Configure AWS credentials from EC2 IAM role (automatic)
# The EC2 instance profile will provide AWS credentials automatically

# Get login token for ECR and login Docker
echo "Logging into Amazon ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Pull Docker images from ECR
echo "Pulling Docker images from ECR..."
docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:${FRONTEND_IMAGE_TAG}
docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:${USER_SERVICE_IMAGE_TAG}
docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:${PRODUCT_SERVICE_IMAGE_TAG}
docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:${CART_SERVICE_IMAGE_TAG}
docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:${ORDER_SERVICE_IMAGE_TAG}

# Create application directory
mkdir -p /opt/ecommerce
cd /opt/ecommerce

# Create docker-compose.yml for running all services
cat > docker-compose.yml <<'DOCKERCOMPOSE'
version: '3.8'

services:
  user-service:
    image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${USER_SERVICE_IMAGE_TAG}
    ports:
      - "3001:3001"
    container_name: user-service
    environment:
      - NODE_ENV=production
    restart: always
    networks:
      - ecommerce-network

  product-service:
    image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${PRODUCT_SERVICE_IMAGE_TAG}
    ports:
      - "3002:3002"
    container_name: product-service
    environment:
      - NODE_ENV=production
    restart: always
    networks:
      - ecommerce-network

  cart-service:
    image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${CART_SERVICE_IMAGE_TAG}
    ports:
      - "3003:3003"
    container_name: cart-service
    environment:
      - NODE_ENV=production
    restart: always
    networks:
      - ecommerce-network

  order-service:
    image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${ORDER_SERVICE_IMAGE_TAG}
    ports:
      - "3004:3004"
    container_name: order-service
    environment:
      - NODE_ENV=production
    restart: always
    networks:
      - ecommerce-network

  frontend:
    image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${FRONTEND_IMAGE_TAG}
    ports:
      - "3000:3000"
    container_name: frontend
    environment:
      - REACT_APP_API_URL=http://$(hostname -I | awk '{print $1}'):3001
      - NODE_ENV=production
    restart: always
    depends_on:
      - user-service
      - product-service
      - cart-service
      - order-service
    networks:
      - ecommerce-network

networks:
  ecommerce-network:
    driver: bridge
DOCKERCOMPOSE

# Replace environment variables in docker-compose.yml
sed -i "s|\${ECR_REGISTRY}|${ECR_REGISTRY}|g" docker-compose.yml
sed -i "s|\${ECR_REPOSITORY}|${ECR_REPOSITORY}|g" docker-compose.yml
sed -i "s|\${USER_SERVICE_IMAGE_TAG}|${USER_SERVICE_IMAGE_TAG}|g" docker-compose.yml
sed -i "s|\${PRODUCT_SERVICE_IMAGE_TAG}|${PRODUCT_SERVICE_IMAGE_TAG}|g" docker-compose.yml
sed -i "s|\${CART_SERVICE_IMAGE_TAG}|${CART_SERVICE_IMAGE_TAG}|g" docker-compose.yml
sed -i "s|\${ORDER_SERVICE_IMAGE_TAG}|${ORDER_SERVICE_IMAGE_TAG}|g" docker-compose.yml
sed -i "s|\${FRONTEND_IMAGE_TAG}|${FRONTEND_IMAGE_TAG}|g" docker-compose.yml

# Run containers using docker-compose
echo "Starting Docker containers..."
cd /opt/ecommerce
docker-compose up -d

# Wait for containers to start
echo "Waiting for containers to initialize..."
sleep 15

# Check container status
echo "Checking container status..."
docker-compose ps
docker ps

# Set up log rotation
cat > /etc/logrotate.d/docker-compose <<'LOGROTATE'
/var/log/user-data.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
}
LOGROTATE

echo "==============================="
echo "✓ EC2 user-data script completed successfully!"
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║        ✓ FRONTEND IS LIVE AND PUBLICLY ACCESSIBLE      ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Services are accessible at:"
echo "  ✓ Frontend (React App):  http://$(hostname -I | awk '{print $1}'):3000"
echo "  ✓ User Service:          http://$(hostname -I | awk '{print $1}'):3001"
echo "  ✓ Product Service:       http://$(hostname -I | awk '{print $1}'):3002"
echo "  ✓ Cart Service:          http://$(hostname -I | awk '{print $1}'):3003"
echo "  ✓ Order Service:         http://$(hostname -I | awk '{print $1}'):3004"
echo ""
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Deployment Timestamp: $(date)"
echo "═══════════════════════════════════════════════════════════"
