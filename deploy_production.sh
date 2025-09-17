#!/bin/bash

# Production Deployment Script for Market Price API
echo "🚀 Starting Production Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create data directory
print_status "Creating data directory..."
mkdir -p backend/data

# Build and start services
print_status "Building and starting services..."
docker-compose -f docker-compose.production.yml up --build -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Check if services are running
print_status "Checking service health..."
if curl -f http://localhost:5004/health > /dev/null 2>&1; then
    print_status "✅ Market Price API is running successfully!"
    print_status "🌐 API URL: http://localhost:5004"
    print_status "📊 Health Check: http://localhost:5004/health"
    print_status "📱 For Android emulator: http://10.0.2.2:5004"
else
    print_error "❌ Service health check failed!"
    print_status "Checking logs..."
    docker-compose -f docker-compose.production.yml logs market-price-api
    exit 1
fi

# Show service status
print_status "Service Status:"
docker-compose -f docker-compose.production.yml ps

print_status "🎉 Production deployment completed successfully!"
print_status "📝 To view logs: docker-compose -f docker-compose.production.yml logs -f"
print_status "🛑 To stop services: docker-compose -f docker-compose.production.yml down"
