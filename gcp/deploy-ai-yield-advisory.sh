#!/bin/bash

# AI Yield Advisory Production Deployment Script
# Deploys Yield Prediction, Weather Integration, and Satellite Soil APIs to Google Cloud Run

set -e

# Configuration
PROJECT_ID="harvest-enterprise-app-1930c"
REGION="us-central1"
SERVICE_ACCOUNT="ultra-crop-sa"

# Service configurations
declare -A SERVICES=(
    ["yield-prediction"]="yield_prediction_api.py:5003:yield-prediction-api"
    ["weather-integration"]="weather_integration_api.py:5005:weather-integration-api"
    ["satellite-soil"]="satellite_soil_api.py:5006:satellite-soil-api"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
print_info() {
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

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi
    
    # Set project
    gcloud config set project $PROJECT_ID
    
    print_success "Prerequisites check passed"
}

# Create service account if it doesn't exist
create_service_account() {
    print_info "Setting up service account..."
    
    # Check if service account exists
    if ! gcloud iam service-accounts describe $SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com &> /dev/null; then
        print_info "Creating service account..."
        gcloud iam service-accounts create $SERVICE_ACCOUNT \
            --display-name="AI Yield Advisory Service Account" \
            --description="Service account for AI Yield Advisory APIs"
        
        # Grant necessary permissions
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
            --role="roles/secretmanager.secretAccessor"
        
        print_success "Service account created"
    else
        print_info "Service account already exists"
    fi
}

# Create secrets if they don't exist
create_secrets() {
    print_info "Setting up secrets..."
    
    # List of required secrets
    declare -a SECRETS=("openweather-api-key" "bhuvan-api-key" "secret-key")
    
    for secret in "${SECRETS[@]}"; do
        if ! gcloud secrets describe $secret &> /dev/null; then
            print_warning "Secret $secret does not exist. Creating with placeholder value..."
            echo "your-$secret-value" | gcloud secrets create $secret --data-file=-
        else
            print_info "Secret $secret already exists"
        fi
    done
    
    print_success "Secrets setup completed"
}

# Build and push Docker image for a service
build_and_push_service() {
    local service_name=$1
    local api_file=$2
    local port=$3
    local cloud_run_name=$4
    
    print_info "Building and pushing $service_name..."
    
    # Get commit SHA
    COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "latest")
    IMAGE_NAME="ai-yield-advisory-$service_name"
    
    # Create Dockerfile for the service
    cat > backend/Dockerfile.$service_name << EOF
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    gcc \\
    g++ \\
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the specific API file
COPY $api_file .

# Create models directory
RUN mkdir -p models

# Expose port
EXPOSE $port

# Run the service
CMD ["python", "$api_file"]
EOF

    # Build the image
    docker build -f backend/Dockerfile.$service_name \
        -t gcr.io/$PROJECT_ID/$IMAGE_NAME:$COMMIT_SHA \
        -t gcr.io/$PROJECT_ID/$IMAGE_NAME:latest \
        ./backend
    
    # Configure Docker authentication
    gcloud auth configure-docker --quiet
    
    # Push the image
    docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:$COMMIT_SHA
    docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:latest
    
    print_success "$service_name image built and pushed"
}

# Deploy service to Cloud Run
deploy_service() {
    local service_name=$1
    local port=$2
    local cloud_run_name=$3
    
    print_info "Deploying $service_name to Cloud Run..."
    
    COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "latest")
    IMAGE_NAME="ai-yield-advisory-$service_name"
    
    gcloud run deploy $cloud_run_name \
        --image=gcr.io/$PROJECT_ID/$IMAGE_NAME:$COMMIT_SHA \
        --region=$REGION \
        --platform=managed \
        --allow-unauthenticated \
        --port=$port \
        --memory=2Gi \
        --cpu=2 \
        --max-instances=10 \
        --min-instances=0 \
        --concurrency=50 \
        --timeout=300 \
        --service-account=$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
        --set-env-vars="ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=$port,DEBUG=false" \
        --set-secrets="OPENWEATHER_API_KEY=openweather-api-key:latest,BHUVAN_API_KEY=bhuvan-api-key:latest,SECRET_KEY=secret-key:latest" \
        --cpu-throttling \
        --execution-environment=gen2 \
        --project=$PROJECT_ID
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe $cloud_run_name --region=$REGION --format="value(status.url)")
    print_success "$service_name deployed successfully!"
    echo "Service URL: $SERVICE_URL"
    echo "Health check: $SERVICE_URL/health"
}

# Test service deployment
test_service() {
    local service_name=$1
    local cloud_run_name=$2
    
    print_info "Testing $service_name deployment..."
    
    SERVICE_URL=$(gcloud run services describe $cloud_run_name --region=$REGION --format="value(status.url)")
    
    # Wait a moment for service to be ready
    sleep 10
    
    # Test health endpoint
    if curl -f "$SERVICE_URL/health" > /dev/null 2>&1; then
        print_success "$service_name health check passed"
    else
        print_warning "$service_name health check failed - service may still be starting up"
    fi
}

# Main deployment function
deploy_all_services() {
    print_info "Starting AI Yield Advisory production deployment..."
    
    for service in "${!SERVICES[@]}"; do
        IFS=':' read -r api_file port cloud_run_name <<< "${SERVICES[$service]}"
        
        echo "=========================================="
        print_info "Deploying $service..."
        echo "API File: $api_file"
        echo "Port: $port"
        echo "Cloud Run Name: $cloud_run_name"
        echo "=========================================="
        
        build_and_push_service "$service" "$api_file" "$port" "$cloud_run_name"
        deploy_service "$service" "$port" "$cloud_run_name"
        test_service "$service" "$cloud_run_name"
        
        echo ""
    done
}

# Generate frontend configuration
generate_frontend_config() {
    print_info "Generating frontend configuration..."
    
    # Get service URLs
    YIELD_PREDICTION_URL=$(gcloud run services describe yield-prediction-api --region=$REGION --format="value(status.url)")
    WEATHER_INTEGRATION_URL=$(gcloud run services describe weather-integration-api --region=$REGION --format="value(status.url)")
    SATELLITE_SOIL_URL=$(gcloud run services describe satellite-soil-api --region=$REGION --format="value(status.url)")
    
    # Create production environment file
    cat > frontend/env.production << EOF
# AI Yield Advisory Production Configuration
YIELD_PREDICTION_API_BASE_URL=$YIELD_PREDICTION_URL
WEATHER_INTEGRATION_API_BASE_URL=$WEATHER_INTEGRATION_URL
SATELLITE_SOIL_API_BASE_URL=$SATELLITE_SOIL_URL

# Other production settings
DEBUG_MODE=false
API_TIMEOUT=30
API_RETRY_COUNT=3
API_RETRY_DELAY=2000
EOF
    
    print_success "Frontend configuration generated"
    print_info "Service URLs:"
    echo "  Yield Prediction: $YIELD_PREDICTION_URL"
    echo "  Weather Integration: $WEATHER_INTEGRATION_URL"
    echo "  Satellite Soil: $SATELLITE_SOIL_URL"
}

# Main execution
main() {
    echo "=========================================="
    echo "AI Yield Advisory Production Deployment"
    echo "=========================================="
    
    check_prerequisites
    create_service_account
    create_secrets
    deploy_all_services
    generate_frontend_config
    
    echo "=========================================="
    print_success "AI Yield Advisory production deployment completed!"
    echo "=========================================="
    print_info "Next steps:"
    echo "1. Update your Flutter app to use the production URLs"
    echo "2. Test the AI Yield Advisory feature in production"
    echo "3. Monitor the services in Google Cloud Console"
    echo ""
    print_info "Service URLs:"
    for service in "${!SERVICES[@]}"; do
        IFS=':' read -r api_file port cloud_run_name <<< "${SERVICES[$service]}"
        SERVICE_URL=$(gcloud run services describe $cloud_run_name --region=$REGION --format="value(status.url)")
        echo "  $service: $SERVICE_URL"
    done
}

# Run main function
main "$@"
