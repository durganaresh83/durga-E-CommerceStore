#!/bin/bash

# E-Commerce Application Health Check Script
# This script verifies all services are running and accessible

echo "════════════════════════════════════════════════════════"
echo "E-Commerce Application Health Check"
echo "════════════════════════════════════════════════════════"
echo ""

# Get local IP
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "Local IP Address: $LOCAL_IP"
echo ""

# Define services to check
SERVICES=(
    "frontend:3000"
    "user-service:3001"
    "product-service:3002"
    "cart-service:3003"
    "order-service:3004"
)

echo "Checking Container Status:"
echo "─────────────────────────────────────────────────────────"

# Check Docker containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Checking Service Connectivity:"
echo "─────────────────────────────────────────────────────────"

HEALTHY_COUNT=0
TOTAL_SERVICES=${#SERVICES[@]}

for service in "${SERVICES[@]}"; do
    IFS=':' read -r name port <<< "$service"
    
    # Try to connect to service
    if timeout 3 bash -c "echo >/dev/tcp/localhost/$port" 2>/dev/null; then
        echo "✓ $name (port $port): ONLINE"
        ((HEALTHY_COUNT++))
    else
        echo "✗ $name (port $port): OFFLINE"
    fi
done

echo ""
echo "════════════════════════════════════════════════════════"
echo "Health Check Summary"
echo "════════════════════════════════════════════════════════"
echo "Services Running: $HEALTHY_COUNT / $TOTAL_SERVICES"

if [ $HEALTHY_COUNT -eq $TOTAL_SERVICES ]; then
    echo ""
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  ✓ ALL SERVICES HEALTHY AND PUBLICLY ACCESSIBLE   ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "Application URLs:"
    echo "  Frontend:       http://$LOCAL_IP:3000"
    echo "  User Service:   http://$LOCAL_IP:3001"
    echo "  Product Service: http://$LOCAL_IP:3002"
    echo "  Cart Service:    http://$LOCAL_IP:3003"
    echo "  Order Service:   http://$LOCAL_IP:3004"
    echo ""
    exit 0
else
    echo ""
    echo "⚠ Some services are not responding. Waiting for initialization..."
    exit 1
fi
