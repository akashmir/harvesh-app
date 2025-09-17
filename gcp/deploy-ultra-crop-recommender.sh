#!/bin/bash

# Ultra Crop Recommender - Google Cloud Run Deployment Script
# Specialized deployment script for the Ultra Crop Recommender API

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
SERVICE_ACCOUNT="ultra-crop-sa"

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "================================================================"
    echo "    ULTRA CROP RECOMMENDER - GOOGLE CLOUD RUN DEPLOYMENT"
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

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check gcloud CLI
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud CLI is not installed. Please install it first:"
        echo "https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    print_success "Google Cloud CLI is available"
    
    # Check if authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with Google Cloud. Please run:"
        echo "gcloud auth login"
        exit 1
    fi
    print_success "Authenticated with Google Cloud"
    
    # Check if project is set
    if [ -z "$PROJECT_ID" ]; then
        print_error "PROJECT_ID is not set. Please set it in the script or export it:"
        echo "export PROJECT_ID=your-project-id"
        exit 1
    fi
    print_success "Project ID: $PROJECT_ID"
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_success "Docker is running"
}

setup_project() {
    print_info "Setting up Google Cloud project..."
    
    # Set project
    gcloud config set project $PROJECT_ID
    
    # Enable required APIs
    print_info "Enabling required APIs..."
    gcloud services enable \
        cloudbuild.googleapis.com \
        run.googleapis.com \
        secretmanager.googleapis.com \
        cloudresourcemanager.googleapis.com \
        container.googleapis.com
    
    print_success "APIs enabled"
}

create_service_account() {
    print_info "Creating service account..."
    
    # Create service account
    gcloud iam service-accounts create $SERVICE_ACCOUNT \
        --display-name="Ultra Crop Recommender Service Account" \
        --description="Service account for Ultra Crop Recommender application" \
        --project=$PROJECT_ID || true
    
    # Grant necessary roles
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="roles/secretmanager.secretAccessor"
    
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="roles/cloudsql.client"
    
    print_success "Service account created and configured"
}

setup_secrets() {
    print_info "Setting up secrets in Secret Manager..."
    
    # Create secrets in Secret Manager
    echo -n "your_openweather_api_key_here" | gcloud secrets create openweather-api-key --data-file=- || true
    echo -n "your_google_earth_engine_key_here" | gcloud secrets create google-earth-engine-key --data-file=- || true
    echo -n "your_bhuvan_api_key_here" | gcloud secrets create bhuvan-api-key --data-file=- || true
    echo -n "ultra-crop-secret-key-$(date +%s)" | gcloud secrets create secret-key --data-file=- || true
    
    print_success "Secrets created in Secret Manager"
    print_warning "Please update the secret values with your actual API keys:"
    echo "  gcloud secrets versions add openweather-api-key --data-file=-"
    echo "  gcloud secrets versions add google-earth-engine-key --data-file=-"
    echo "  gcloud secrets versions add bhuvan-api-key --data-file=-"
}

build_and_push_image() {
    print_info "Building and pushing Docker image for Ultra Crop Recommender..."
    
    # Configure Docker for GCR
    gcloud auth configure-docker
    
    # Build image
    print_info "Building Docker image..."
    docker build -f backend/Dockerfile.cloudrun -t gcr.io/$PROJECT_ID/$IMAGE_NAME:latest ./backend
    
    # Push image
    print_info "Pushing image to Google Container Registry..."
    docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:latest
    
    print_success "Image built and pushed successfully"
}

deploy_to_cloud_run() {
    print_info "Deploying Ultra Crop Recommender to Cloud Run..."
    
    # Deploy the service
    gcloud run deploy $SERVICE_NAME \
        --image gcr.io/$PROJECT_ID/$IMAGE_NAME:latest \
        --region $REGION \
        --platform managed \
        --allow-unauthenticated \
        --port 5020 \
        --memory 4Gi \
        --cpu 4 \
        --max-instances 20 \
        --min-instances 1 \
        --concurrency 50 \
        --timeout 600 \
        --service-account ${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com \
        --set-env-vars "ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5020,DEBUG=false,MODEL_PATH=/app/models,CACHE_TTL=3600,ULTRA_REQUEST_TIMEOUT=10.0" \
        --set-secrets "OPENWEATHER_API_KEY=openweather-api-key:latest,GOOGLE_EARTH_ENGINE_KEY=google-earth-engine-key:latest,BHUVAN_API_KEY=bhuvan-api-key:latest,SECRET_KEY=secret-key:latest"
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")
    print_success "Ultra Crop Recommender deployed successfully!"
    echo "Service URL: $SERVICE_URL"
}

test_deployment() {
    print_info "Testing Ultra Crop Recommender deployment..."
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")
    
    # Test health endpoint
    print_info "Testing health endpoint..."
    if curl -f "$SERVICE_URL/health" > /dev/null 2>&1; then
        print_success "Health check passed"
    else
        print_warning "Health check failed - service may still be starting up"
    fi
    
    # Test main recommendation endpoint
    print_info "Testing recommendation endpoint..."
    TEST_PAYLOAD='{
        "location": {
            "latitude": 28.6139,
            "longitude": 77.2090
        },
        "soil_data": {
            "nitrogen": 50,
            "phosphorus": 30,
            "potassium": 40,
            "ph": 6.5,
            "organic_carbon": 1.2
        },
        "weather_data": {
            "temperature": 25,
            "humidity": 60,
            "rainfall": 100
        },
        "field_size": 1.0,
        "budget": 50000,
        "preferred_crops": ["rice", "wheat"],
        "season": "kharif"
    }'
    
    if curl -X POST "$SERVICE_URL/ultra-recommend" \
        -H "Content-Type: application/json" \
        -d "$TEST_PAYLOAD" \
        --max-time 30 > /dev/null 2>&1; then
        print_success "Recommendation endpoint test passed"
    else
        print_warning "Recommendation endpoint test failed - check logs for details"
    fi
    
    echo ""
    print_success "Deployment testing completed!"
    echo "Service URL: $SERVICE_URL"
    echo "Health Check: $SERVICE_URL/health"
    echo "API Documentation: $SERVICE_URL/docs"
}

show_logs() {
    print_info "Showing recent logs..."
    gcloud run logs read $SERVICE_NAME --region=$REGION --limit=50
}

cleanup() {
    print_info "Cleaning up Ultra Crop Recommender resources..."
    
    # Delete Cloud Run service
    gcloud run services delete $SERVICE_NAME --region=$REGION --quiet || true
    
    # Delete images
    gcloud container images delete gcr.io/$PROJECT_ID/$IMAGE_NAME:latest --quiet || true
    
    print_success "Cleanup completed"
}

show_help() {
    echo "Ultra Crop Recommender - Google Cloud Run Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  setup                 Setup GCP project and enable APIs"
    echo "  deploy                Deploy Ultra Crop Recommender to Cloud Run"
    echo "  test                  Test deployment"
    echo "  logs                  Show service logs"
    echo "  cleanup               Clean up resources"
    echo "  help                  Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  PROJECT_ID            Google Cloud Project ID (required)"
    echo "  REGION                Deployment region (default: us-central1)"
    echo "  SERVICE_NAME          Cloud Run service name (default: ultra-crop-recommender-api)"
    echo ""
    echo "Examples:"
    echo "  PROJECT_ID=my-project $0 setup"
    echo "  PROJECT_ID=my-project $0 deploy"
    echo "  PROJECT_ID=my-project $0 test"
    echo "  PROJECT_ID=my-project $0 logs"
    echo "  PROJECT_ID=my-project $0 cleanup"
}

# Main script
main() {
    print_header
    
    # Set PROJECT_ID from environment or argument
    if [ -n "$1" ] && [ "$1" != "setup" ] && [ "$1" != "deploy" ] && [ "$1" != "test" ] && [ "$1" != "logs" ] && [ "$1" != "cleanup" ] && [ "$1" != "help" ]; then
        PROJECT_ID="$1"
    fi
    
    if [ -z "$PROJECT_ID" ]; then
        print_error "PROJECT_ID is required. Set it as environment variable or first argument."
        echo "Example: PROJECT_ID=my-project $0 setup"
        exit 1
    fi
    
    case "${2:-setup}" in
        "setup")
            check_prerequisites
            setup_project
            create_service_account
            setup_secrets
            print_success "GCP setup completed!"
            ;;
        "deploy")
            check_prerequisites
            build_and_push_image
            deploy_to_cloud_run
            test_deployment
            ;;
        "test")
            test_deployment
            ;;
        "logs")
            show_logs
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $2"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
