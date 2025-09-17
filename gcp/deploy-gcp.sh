#!/bin/bash

# Ultra Crop Recommender - Google Cloud Platform Deployment Script
# Supports Cloud Run, GKE, and App Engine deployments

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
ZONE="us-central1-a"
CLUSTER_NAME="ultra-crop-cluster"
SERVICE_ACCOUNT="ultra-crop-sa"
DEPLOYMENT_TYPE="cloudrun"  # cloudrun, gke, appengine

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "================================================================"
    echo "    ULTRA CROP RECOMMENDER - GOOGLE CLOUD DEPLOYMENT"
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
        container.googleapis.com \
        compute.googleapis.com \
        secretmanager.googleapis.com \
        cloudresourcemanager.googleapis.com
    
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
        --role="roles/cloudsql.client"
    
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="roles/secretmanager.secretAccessor"
    
    print_success "Service account created and configured"
}

setup_secrets() {
    print_info "Setting up secrets..."
    
    # Create secrets in Secret Manager
    echo -n "your_openweather_api_key_here" | gcloud secrets create openweather-api-key --data-file=- || true
    echo -n "your_soil_grids_api_key_here" | gcloud secrets create soil-grids-api-key --data-file=- || true
    echo -n "your_google_maps_api_key_here" | gcloud secrets create google-maps-api-key --data-file=- || true
    echo -n "ultra-crop-secret-key-$(date +%s)" | gcloud secrets create secret-key --data-file=- || true
    
    print_success "Secrets created in Secret Manager"
}

build_and_push_images() {
    print_info "Building and pushing Docker images..."
    
    # Configure Docker for GCR
    gcloud auth configure-docker
    
    # Build and push backend
    print_info "Building backend image..."
    docker build -t gcr.io/$PROJECT_ID/ultra-crop-api:latest ./backend
    docker push gcr.io/$PROJECT_ID/ultra-crop-api:latest
    
    # Build and push frontend
    print_info "Building frontend image..."
    docker build -t gcr.io/$PROJECT_ID/ultra-crop-frontend:latest ./frontend
    docker push gcr.io/$PROJECT_ID/ultra-crop-frontend:latest
    
    print_success "Images built and pushed to GCR"
}

deploy_cloud_run() {
    print_info "Deploying to Cloud Run..."
    
    # Deploy backend
    print_info "Deploying backend API..."
    gcloud run deploy ultra-crop-api \
        --image gcr.io/$PROJECT_ID/ultra-crop-api:latest \
        --region $REGION \
        --platform managed \
        --allow-unauthenticated \
        --port 5020 \
        --memory 2Gi \
        --cpu 2 \
        --max-instances 10 \
        --set-env-vars "ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5020" \
        --set-secrets "OPENWEATHER_API_KEY=openweather-api-key:latest,SOIL_GRIDS_API_KEY=soil-grids-api-key:latest,SECRET_KEY=secret-key:latest"
    
    # Get backend URL
    BACKEND_URL=$(gcloud run services describe ultra-crop-api --region=$REGION --format="value(status.url)")
    print_success "Backend deployed: $BACKEND_URL"
    
    # Deploy frontend
    print_info "Deploying frontend..."
    gcloud run deploy ultra-crop-frontend \
        --image gcr.io/$PROJECT_ID/ultra-crop-frontend:latest \
        --region $REGION \
        --platform managed \
        --allow-unauthenticated \
        --port 80 \
        --memory 1Gi \
        --cpu 1 \
        --max-instances 5 \
        --set-env-vars "ULTRA_CROP_API_BASE_URL=$BACKEND_URL" \
        --set-secrets "GOOGLE_MAPS_API_KEY=google-maps-api-key:latest"
    
    # Get frontend URL
    FRONTEND_URL=$(gcloud run services describe ultra-crop-frontend --region=$REGION --format="value(status.url)")
    print_success "Frontend deployed: $FRONTEND_URL"
    
    echo ""
    print_success "Cloud Run deployment completed!"
    echo "Backend API: $BACKEND_URL"
    echo "Frontend: $FRONTEND_URL"
}

deploy_gke() {
    print_info "Deploying to Google Kubernetes Engine..."
    
    # Create GKE cluster
    print_info "Creating GKE cluster..."
    gcloud container clusters create $CLUSTER_NAME \
        --zone $ZONE \
        --num-nodes 3 \
        --enable-autoscaling \
        --min-nodes 1 \
        --max-nodes 10 \
        --machine-type e2-standard-2 \
        --enable-autorepair \
        --enable-autoupgrade
    
    # Get cluster credentials
    gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE
    
    # Update image references in Kubernetes manifests
    sed -i "s/PROJECT_ID/$PROJECT_ID/g" gcp/k8s/*.yaml
    
    # Apply Kubernetes manifests
    print_info "Applying Kubernetes manifests..."
    kubectl apply -f gcp/k8s/namespace.yaml
    kubectl apply -f gcp/k8s/configmap.yaml
    kubectl apply -f gcp/k8s/secret.yaml
    kubectl apply -f gcp/k8s/backend-deployment.yaml
    kubectl apply -f gcp/k8s/frontend-deployment.yaml
    kubectl apply -f gcp/k8s/services.yaml
    kubectl apply -f gcp/k8s/ingress.yaml
    
    # Wait for deployments
    print_info "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/ultra-crop-api -n ultra-crop
    kubectl wait --for=condition=available --timeout=300s deployment/ultra-crop-frontend -n ultra-crop
    
    # Get service URLs
    BACKEND_IP=$(kubectl get service ultra-crop-api-service -n ultra-crop -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    FRONTEND_IP=$(kubectl get service ultra-crop-frontend-service -n ultra-crop -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    print_success "GKE deployment completed!"
    echo "Backend API: http://$BACKEND_IP:5020"
    echo "Frontend: http://$FRONTEND_IP:80"
}

deploy_app_engine() {
    print_info "Deploying to App Engine..."
    
    # Create app.yaml for backend
    cat > gcp/app.yaml << EOF
runtime: python39
service: ultra-crop-api

env_variables:
  API_HOST: "0.0.0.0"
  API_PORT: "8080"
  DEBUG: "false"
  ENVIRONMENT: "production"

automatic_scaling:
  min_instances: 1
  max_instances: 10
  target_cpu_utilization: 0.6

resources:
  cpu: 2
  memory_gb: 2
  disk_size_gb: 10
EOF
    
    # Deploy to App Engine
    gcloud app deploy gcp/app.yaml --quiet
    
    print_success "App Engine deployment completed!"
    echo "Backend API: https://ultra-crop-api-dot-$PROJECT_ID.appspot.com"
}

test_deployment() {
    print_info "Testing deployment..."
    
    case $DEPLOYMENT_TYPE in
        "cloudrun")
            BACKEND_URL=$(gcloud run services describe ultra-crop-api --region=$REGION --format="value(status.url)")
            FRONTEND_URL=$(gcloud run services describe ultra-crop-frontend --region=$REGION --format="value(status.url)")
            ;;
        "gke")
            BACKEND_IP=$(kubectl get service ultra-crop-api-service -n ultra-crop -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
            FRONTEND_IP=$(kubectl get service ultra-crop-frontend-service -n ultra-crop -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
            BACKEND_URL="http://$BACKEND_IP:5020"
            FRONTEND_URL="http://$FRONTEND_IP:80"
            ;;
        "appengine")
            BACKEND_URL="https://ultra-crop-api-dot-$PROJECT_ID.appspot.com"
            FRONTEND_URL="https://$PROJECT_ID.appspot.com"
            ;;
    esac
    
    # Test backend health
    if curl -f "$BACKEND_URL/health" > /dev/null 2>&1; then
        print_success "Backend API health check passed"
    else
        print_warning "Backend API health check failed"
    fi
    
    # Test frontend
    if curl -f "$FRONTEND_URL" > /dev/null 2>&1; then
        print_success "Frontend accessibility check passed"
    else
        print_warning "Frontend accessibility check failed"
    fi
    
    echo ""
    print_success "Deployment URLs:"
    echo "Backend API: $BACKEND_URL"
    echo "Frontend: $FRONTEND_URL"
}

cleanup() {
    print_info "Cleaning up resources..."
    
    case $DEPLOYMENT_TYPE in
        "cloudrun")
            gcloud run services delete ultra-crop-api --region=$REGION --quiet || true
            gcloud run services delete ultra-crop-frontend --region=$REGION --quiet || true
            ;;
        "gke")
            gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE --quiet || true
            ;;
        "appengine")
            gcloud app services delete ultra-crop-api --quiet || true
            ;;
    esac
    
    print_success "Cleanup completed"
}

show_help() {
    echo "Ultra Crop Recommender - Google Cloud Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  setup                 Setup GCP project and enable APIs"
    echo "  deploy [type]         Deploy application (cloudrun, gke, appengine)"
    echo "  test                  Test deployment"
    echo "  cleanup               Clean up resources"
    echo "  help                  Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  PROJECT_ID            Google Cloud Project ID (required)"
    echo "  REGION                Deployment region (default: us-central1)"
    echo "  ZONE                  GKE zone (default: us-central1-a)"
    echo "  CLUSTER_NAME          GKE cluster name (default: ultra-crop-cluster)"
    echo ""
    echo "Examples:"
    echo "  PROJECT_ID=my-project $0 setup"
    echo "  PROJECT_ID=my-project $0 deploy cloudrun"
    echo "  PROJECT_ID=my-project $0 deploy gke"
    echo "  PROJECT_ID=my-project $0 test"
    echo "  PROJECT_ID=my-project $0 cleanup"
}

# Main script
main() {
    print_header
    
    # Set PROJECT_ID from environment or argument
    if [ -n "$1" ] && [ "$1" != "setup" ] && [ "$1" != "deploy" ] && [ "$1" != "test" ] && [ "$1" != "cleanup" ] && [ "$1" != "help" ]; then
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
            DEPLOYMENT_TYPE="${3:-cloudrun}"
            check_prerequisites
            build_and_push_images
            case $DEPLOYMENT_TYPE in
                "cloudrun")
                    deploy_cloud_run
                    ;;
                "gke")
                    deploy_gke
                    ;;
                "appengine")
                    deploy_app_engine
                    ;;
                *)
                    print_error "Invalid deployment type: $DEPLOYMENT_TYPE"
                    print_info "Valid types: cloudrun, gke, appengine"
                    exit 1
                    ;;
            esac
            test_deployment
            ;;
        "test")
            test_deployment
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
