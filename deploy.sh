#!/bin/bash

# Ultra Crop Recommender - Deployment Script
# Supports multiple deployment platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ultra-crop-recommender"
VERSION="1.0.0"
DOCKER_REGISTRY="your-registry.com"
ENVIRONMENT="production"

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "================================================================"
    echo "           ULTRA CROP RECOMMENDER - DEPLOYMENT SCRIPT"
    echo "                    Version: $VERSION"
    echo "================================================================"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_success "Docker is available"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    print_success "Docker Compose is available"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    print_success "Docker daemon is running"
}

create_environment_file() {
    print_info "Creating environment configuration..."
    
    if [ ! -f .env ]; then
        cat > .env << EOF
# Ultra Crop Recommender Environment Configuration
# Generated on $(date)

# API Configuration
API_HOST=0.0.0.0
API_PORT=5020
DEBUG=false
MODEL_PATH=./models
CACHE_TTL=3600

# External APIs
OPENWEATHER_API_KEY=your_openweather_api_key_here
SOIL_GRIDS_API_KEY=your_soil_grids_api_key_here

# Database Configuration
POSTGRES_PASSWORD=ultra_crop_secure_password_2024
DATABASE_URL=postgresql://ultra_crop_user:ultra_crop_secure_password_2024@postgres:5432/ultra_crop

# Security
SECRET_KEY=ultra-crop-secret-key-2024-$(openssl rand -hex 16)

# Frontend Configuration
ULTRA_CROP_API_BASE_URL=http://ultra-crop-api:5020

# Deployment
ENVIRONMENT=production
VERSION=$VERSION
EOF
        print_success "Environment file created: .env"
    else
        print_warning "Environment file already exists: .env"
    fi
}

build_images() {
    print_info "Building Docker images..."
    
    # Build backend
    print_info "Building backend API image..."
    docker build -t $PROJECT_NAME-api:$VERSION ./backend
    docker tag $PROJECT_NAME-api:$VERSION $PROJECT_NAME-api:latest
    print_success "Backend API image built"
    
    # Build frontend
    print_info "Building frontend image..."
    docker build -t $PROJECT_NAME-frontend:$VERSION ./frontend
    docker tag $PROJECT_NAME-frontend:$VERSION $PROJECT_NAME-frontend:latest
    print_success "Frontend image built"
}

deploy_local() {
    print_info "Deploying locally with Docker Compose..."
    
    # Stop existing containers
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Start services
    docker-compose up -d
    
    # Wait for services to be ready
    print_info "Waiting for services to start..."
    sleep 30
    
    # Check health
    if curl -f http://localhost:5020/health > /dev/null 2>&1; then
        print_success "Backend API is healthy"
    else
        print_warning "Backend API health check failed"
    fi
    
    if curl -f http://localhost:80 > /dev/null 2>&1; then
        print_success "Frontend is accessible"
    else
        print_warning "Frontend health check failed"
    fi
    
    print_success "Local deployment completed!"
    print_info "Backend API: http://localhost:5020"
    print_info "Frontend: http://localhost:80"
}

deploy_cloud() {
    local platform=$1
    
    case $platform in
        "aws")
            deploy_aws
            ;;
        "gcp")
            deploy_gcp
            ;;
        "azure")
            deploy_azure
            ;;
        *)
            print_error "Unsupported cloud platform: $platform"
            print_info "Supported platforms: aws, gcp, azure"
            exit 1
            ;;
    esac
}

deploy_aws() {
    print_info "Deploying to AWS..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check ECS CLI
    if ! command -v ecs-cli &> /dev/null; then
        print_warning "ECS CLI not found. Installing..."
        # Install ECS CLI (simplified)
        print_info "Please install ECS CLI manually: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html"
    fi
    
    print_info "AWS deployment would be implemented here"
    print_warning "AWS deployment is not fully implemented yet"
}

deploy_gcp() {
    print_info "Deploying to Google Cloud Platform..."
    
    # Check gcloud CLI
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud CLI is not installed. Please install gcloud CLI first."
        exit 1
    fi
    
    print_info "GCP deployment would be implemented here"
    print_warning "GCP deployment is not fully implemented yet"
}

deploy_azure() {
    print_info "Deploying to Microsoft Azure..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    fi
    
    print_info "Azure deployment would be implemented here"
    print_warning "Azure deployment is not fully implemented yet"
}

run_tests() {
    print_info "Running deployment tests..."
    
    # Test backend API
    if curl -f http://localhost:5020/health > /dev/null 2>&1; then
        print_success "Backend API health check passed"
    else
        print_error "Backend API health check failed"
        return 1
    fi
    
    # Test frontend
    if curl -f http://localhost:80 > /dev/null 2>&1; then
        print_success "Frontend accessibility check passed"
    else
        print_error "Frontend accessibility check failed"
        return 1
    fi
    
    # Test API endpoints
    print_info "Testing API endpoints..."
    
    # Test ultra-recommend endpoint
    response=$(curl -s -X POST http://localhost:5020/ultra-recommend \
        -H "Content-Type: application/json" \
        -d '{"latitude": 28.6139, "longitude": 77.2090, "farm_size": 1.0, "irrigation_type": "drip", "language": "en"}')
    
    if echo "$response" | grep -q '"success":true'; then
        print_success "Ultra recommend endpoint test passed"
    else
        print_error "Ultra recommend endpoint test failed"
        return 1
    fi
    
    print_success "All tests passed!"
}

cleanup() {
    print_info "Cleaning up..."
    
    # Stop containers
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Remove unused images
    docker image prune -f
    
    print_success "Cleanup completed"
}

show_help() {
    echo "Ultra Crop Recommender - Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  local                 Deploy locally with Docker Compose"
    echo "  cloud [platform]      Deploy to cloud platform (aws, gcp, azure)"
    echo "  build                 Build Docker images only"
    echo "  test                  Run deployment tests"
    echo "  cleanup               Clean up Docker resources"
    echo "  help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 local              Deploy locally"
    echo "  $0 cloud aws          Deploy to AWS"
    echo "  $0 build              Build images only"
    echo "  $0 test               Run tests"
    echo "  $0 cleanup            Clean up"
}

# Main script
main() {
    print_header
    
    case "${1:-local}" in
        "local")
            check_dependencies
            create_environment_file
            build_images
            deploy_local
            run_tests
            ;;
        "cloud")
            if [ -z "$2" ]; then
                print_error "Please specify cloud platform: aws, gcp, or azure"
                exit 1
            fi
            check_dependencies
            create_environment_file
            build_images
            deploy_cloud "$2"
            ;;
        "build")
            check_dependencies
            build_images
            ;;
        "test")
            run_tests
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
