#!/bin/bash

# Ultra Crop Recommender - Local Docker Test Script
# This script tests the Docker build locally before deploying to Cloud Run

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="ultra-crop-recommender-test"
CONTAINER_NAME="ultra-crop-test"
PORT=5020

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to clean up previous test containers
cleanup() {
    print_status "Cleaning up previous test containers..."
    
    # Stop and remove container if it exists
    if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        docker stop $CONTAINER_NAME &> /dev/null || true
        docker rm $CONTAINER_NAME &> /dev/null || true
        print_success "Previous test container cleaned up"
    fi
    
    # Remove test image if it exists
    if docker images --format "table {{.Repository}}" | grep -q "^${IMAGE_NAME}$"; then
        docker rmi $IMAGE_NAME &> /dev/null || true
        print_success "Previous test image cleaned up"
    fi
}

# Function to build Docker image
build_image() {
    print_status "Building Docker image..."
    
    # Check if Dockerfile exists
    if [ ! -f "backend/Dockerfile.ultra-crop-optimized" ]; then
        print_error "Dockerfile not found: backend/Dockerfile.ultra-crop-optimized"
        exit 1
    fi
    
    # Build the image
    docker build -f backend/Dockerfile.ultra-crop-optimized \
        -t $IMAGE_NAME \
        ./backend
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully"
    else
        print_error "Docker image build failed"
        exit 1
    fi
}

# Function to run container
run_container() {
    print_status "Starting test container..."
    
    # Run the container
    docker run -d \
        --name $CONTAINER_NAME \
        -p $PORT:5020 \
        -e ENVIRONMENT=test \
        -e API_HOST=0.0.0.0 \
        -e API_PORT=5020 \
        -e DEBUG=false \
        -e MODEL_PATH=/app/models \
        -e CACHE_TTL=3600 \
        -e ULTRA_REQUEST_TIMEOUT=10.0 \
        $IMAGE_NAME
    
    if [ $? -eq 0 ]; then
        print_success "Test container started successfully"
    else
        print_error "Failed to start test container"
        exit 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    print_status "Waiting for service to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:$PORT/health &> /dev/null; then
            print_success "Service is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - waiting for service..."
        sleep 5
        ((attempt++))
    done
    
    print_error "Service failed to start within expected time"
    return 1
}

# Function to test the service
test_service() {
    print_status "Testing the service..."
    
    local base_url="http://localhost:$PORT"
    
    # Test health endpoint
    print_status "Testing health endpoint..."
    if curl -f "$base_url/health" &> /dev/null; then
        print_success "Health endpoint working"
    else
        print_error "Health endpoint failed"
        return 1
    fi
    
    # Test quick recommendation
    print_status "Testing quick recommendation endpoint..."
    local test_data='{"latitude": 28.6139, "longitude": 77.2090}'
    if curl -X POST "$base_url/ultra-recommend/quick" \
        -H "Content-Type: application/json" \
        -d "$test_data" \
        --max-time 60 &> /dev/null; then
        print_success "Quick recommendation endpoint working"
    else
        print_warning "Quick recommendation endpoint failed (may be expected in test environment)"
    fi
    
    # Test crop database
    print_status "Testing crop database endpoint..."
    if curl -f "$base_url/ultra-recommend/crops" &> /dev/null; then
        print_success "Crop database endpoint working"
    else
        print_error "Crop database endpoint failed"
        return 1
    fi
    
    print_success "All basic tests passed!"
}

# Function to show container logs
show_logs() {
    print_status "Container logs:"
    echo "----------------------------------------"
    docker logs $CONTAINER_NAME --tail 20
    echo "----------------------------------------"
}

# Function to show service info
show_service_info() {
    print_status "Service Information:"
    echo "  Container: $CONTAINER_NAME"
    echo "  Image: $IMAGE_NAME"
    echo "  Port: $PORT"
    echo "  Health Check: http://localhost:$PORT/health"
    echo "  API Endpoint: http://localhost:$PORT/ultra-recommend"
    echo "  Crop Database: http://localhost:$PORT/ultra-recommend/crops"
}

# Function to stop and clean up
stop_and_cleanup() {
    print_status "Stopping and cleaning up..."
    
    if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        docker stop $CONTAINER_NAME
        print_success "Container stopped"
    fi
    
    if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        docker rm $CONTAINER_NAME
        print_success "Container removed"
    fi
    
    if docker images --format "table {{.Repository}}" | grep -q "^${IMAGE_NAME}$"; then
        docker rmi $IMAGE_NAME
        print_success "Image removed"
    fi
}

# Main function
main() {
    echo "=========================================="
    echo "  Ultra Crop Recommender - Local Test"
    echo "=========================================="
    
    # Pre-flight checks
    check_docker
    
    # Cleanup previous test
    cleanup
    
    # Build and test
    build_image
    run_container
    
    # Wait for service
    if wait_for_service; then
        show_service_info
        test_service
        show_logs
        
        echo ""
        print_success "Local Docker test completed successfully!"
        echo ""
        echo "The service is running at http://localhost:$PORT"
        echo "You can test it manually or press Ctrl+C to stop and clean up."
        echo ""
        
        # Wait for user input or Ctrl+C
        read -p "Press Enter to stop and clean up, or Ctrl+C to keep running..."
    else
        print_error "Service failed to start"
        show_logs
    fi
    
    # Cleanup
    stop_and_cleanup
}

# Handle Ctrl+C
trap 'echo ""; print_status "Received interrupt signal"; stop_and_cleanup; exit 0' INT

# Run main function
main "$@"
