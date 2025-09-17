#!/bin/bash

# Ultra Crop Recommender - Optimized Deployment Script
# This script deploys the ultra crop recommender API to Google Cloud Run

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=""
REGION="us-central1"
SERVICE_NAME="ultra-crop-recommender-api"
IMAGE_NAME="ultra-crop-recommender"
SERVICE_ACCOUNT="ultra-crop-sa@${PROJECT_ID}.iam.gserviceaccount.com"

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

# Function to check if gcloud is installed and authenticated
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi
}

# Function to get project ID
get_project_id() {
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
        if [ -z "$PROJECT_ID" ]; then
            print_error "No project ID set. Please set it with 'gcloud config set project YOUR_PROJECT_ID'"
            exit 1
        fi
    fi
    print_status "Using project: $PROJECT_ID"
}

# Function to enable required APIs
enable_apis() {
    print_status "Enabling required Google Cloud APIs..."
    gcloud services enable cloudbuild.googleapis.com \
        run.googleapis.com \
        containerregistry.googleapis.com \
        secretmanager.googleapis.com \
        --project=$PROJECT_ID
    print_success "APIs enabled successfully"
}

# Function to create service account if it doesn't exist
create_service_account() {
    print_status "Checking service account..."
    if ! gcloud iam service-accounts describe $SERVICE_ACCOUNT --project=$PROJECT_ID &>/dev/null; then
        print_status "Creating service account: $SERVICE_ACCOUNT"
        gcloud iam service-accounts create ultra-crop-sa \
            --display-name="Ultra Crop Recommender Service Account" \
            --description="Service account for Ultra Crop Recommender API" \
            --project=$PROJECT_ID
        
        # Grant necessary permissions
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:$SERVICE_ACCOUNT" \
            --role="roles/secretmanager.secretAccessor"
        
        print_success "Service account created and configured"
    else
        print_success "Service account already exists"
    fi
}

# Function to create secrets if they don't exist
create_secrets() {
    print_status "Checking secrets..."
    
    # List of required secrets
    secrets=("openweather-api-key" "google-earth-engine-key" "bhuvan-api-key" "secret-key")
    
    for secret in "${secrets[@]}"; do
        if ! gcloud secrets describe $secret --project=$PROJECT_ID &>/dev/null; then
            print_warning "Secret $secret does not exist. Creating placeholder..."
            echo "your-$secret-here" | gcloud secrets create $secret \
                --data-file=- \
                --project=$PROJECT_ID
            print_success "Placeholder secret $secret created. Please update with real values."
        else
            print_success "Secret $secret already exists"
        fi
    done
}

# Function to build and push Docker image
build_and_push() {
    print_status "Building Docker image..."
    
    # Get the latest commit SHA
    COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "latest")
    
    # Build the image
    docker build -f backend/Dockerfile.ultra-crop-optimized \
        -t gcr.io/$PROJECT_ID/$IMAGE_NAME:$COMMIT_SHA \
        -t gcr.io/$PROJECT_ID/$IMAGE_NAME:latest \
        ./backend
    
    print_success "Docker image built successfully"
    
    # Configure Docker to use gcloud as a credential helper
    gcloud auth configure-docker --quiet
    
    # Push the image
    print_status "Pushing Docker image to Container Registry..."
    docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:$COMMIT_SHA
    docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:latest
    
    print_success "Docker image pushed successfully"
}

# Function to deploy to Cloud Run
deploy_to_cloud_run() {
    print_status "Deploying to Cloud Run..."
    
    # Get the latest commit SHA
    COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "latest")
    
    gcloud run deploy $SERVICE_NAME \
        --image=gcr.io/$PROJECT_ID/$IMAGE_NAME:$COMMIT_SHA \
        --region=$REGION \
        --platform=managed \
        --allow-unauthenticated \
        --port=5020 \
        --memory=4Gi \
        --cpu=4 \
        --max-instances=20 \
        --min-instances=1 \
        --concurrency=50 \
        --timeout=600 \
        --service-account=$SERVICE_ACCOUNT \
        --set-env-vars="ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5020,DEBUG=false,MODEL_PATH=/app/models,CACHE_TTL=3600,ULTRA_REQUEST_TIMEOUT=10.0" \
        --set-secrets="OPENWEATHER_API_KEY=openweather-api-key:latest,GOOGLE_EARTH_ENGINE_KEY=google-earth-engine-key:latest,BHUVAN_API_KEY=bhuvan-api-key:latest,SECRET_KEY=secret-key:latest" \
        --cpu-throttling \
        --execution-environment=gen2 \
        --project=$PROJECT_ID
    
    print_success "Deployment completed successfully"
}

# Function to get service URL
get_service_url() {
    print_status "Getting service URL..."
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
        --region=$REGION \
        --platform=managed \
        --format="value(status.url)" \
        --project=$PROJECT_ID)
    
    print_success "Service deployed at: $SERVICE_URL"
    print_status "Health check: $SERVICE_URL/health"
    print_status "API endpoint: $SERVICE_URL/ultra-recommend"
}

# Function to test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    if [ -n "$SERVICE_URL" ]; then
        # Test health endpoint
        if curl -f "$SERVICE_URL/health" &>/dev/null; then
            print_success "Health check passed"
        else
            print_warning "Health check failed - service may still be starting up"
        fi
        
        # Test API endpoint with sample data
        print_status "Testing API endpoint with sample data..."
        curl -X POST "$SERVICE_URL/ultra-recommend" \
            -H "Content-Type: application/json" \
            -d '{"latitude": 28.6139, "longitude": 77.2090, "farm_size": 1.0}' \
            --max-time 30 || print_warning "API test failed - service may still be starting up"
    fi
}

# Main deployment function
main() {
    echo "=========================================="
    echo "  Ultra Crop Recommender Deployment"
    echo "=========================================="
    
    # Pre-deployment checks
    check_gcloud
    get_project_id
    
    # Setup
    enable_apis
    create_service_account
    create_secrets
    
    # Build and deploy
    build_and_push
    deploy_to_cloud_run
    get_service_url
    
    # Test
    test_deployment
    
    echo "=========================================="
    print_success "Deployment completed successfully!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Update secrets with real API keys:"
    echo "   gcloud secrets versions add openweather-api-key --data-file=-"
    echo "2. Test the API: $SERVICE_URL/health"
    echo "3. Monitor logs: gcloud run logs tail $SERVICE_NAME --region=$REGION"
    echo ""
}

# Run main function
main "$@"
