#!/bin/bash

# Check existing Google Cloud deployment status
# This script helps you understand what's currently deployed

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}"
    echo "================================================================"
    echo "    CHECKING EXISTING ULTRA CROP RECOMMENDER DEPLOYMENT"
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

check_cloud_run() {
    print_info "Checking Cloud Run services..."
    
    # Check if any ultra-crop services exist
    SERVICES=$(gcloud run services list --filter="metadata.name:ultra-crop" --format="value(metadata.name)" 2>/dev/null || echo "")
    
    if [ -n "$SERVICES" ]; then
        print_success "Found Cloud Run services:"
        gcloud run services list --filter="metadata.name:ultra-crop" --format="table(metadata.name,status.url,status.conditions[0].status)"
        
        # Check each service
        for service in $SERVICES; do
            print_info "Checking service: $service"
            URL=$(gcloud run services describe $service --format="value(status.url)" 2>/dev/null || echo "")
            if [ -n "$URL" ]; then
                print_success "Service URL: $URL"
                
                # Test health endpoint
                if curl -f "$URL/health" > /dev/null 2>&1; then
                    print_success "Health check passed"
                else
                    print_warning "Health check failed"
                fi
            fi
        done
    else
        print_warning "No Cloud Run services found with 'ultra-crop' in name"
    fi
}

check_gke() {
    print_info "Checking Google Kubernetes Engine..."
    
    # Check if any clusters exist
    CLUSTERS=$(gcloud container clusters list --format="value(name)" 2>/dev/null || echo "")
    
    if [ -n "$CLUSTERS" ]; then
        print_success "Found GKE clusters:"
        gcloud container clusters list --format="table(name,location,status,currentMasterVersion)"
        
        # Check for ultra-crop namespace
        for cluster in $CLUSTERS; do
            print_info "Checking cluster: $cluster"
            ZONE=$(gcloud container clusters describe $cluster --format="value(location)" 2>/dev/null || echo "")
            
            if [ -n "$ZONE" ]; then
                gcloud container clusters get-credentials $cluster --zone=$ZONE 2>/dev/null || true
                
                # Check for ultra-crop namespace
                if kubectl get namespace ultra-crop > /dev/null 2>&1; then
                    print_success "Found ultra-crop namespace in cluster: $cluster"
                    kubectl get pods -n ultra-crop
                    kubectl get services -n ultra-crop
                else
                    print_warning "No ultra-crop namespace found in cluster: $cluster"
                fi
            fi
        done
    else
        print_warning "No GKE clusters found"
    fi
}

check_app_engine() {
    print_info "Checking App Engine..."
    
    # Check if App Engine is enabled
    if gcloud app describe > /dev/null 2>&1; then
        print_success "App Engine is enabled"
        gcloud app services list
        
        # Check for ultra-crop service
        if gcloud app services describe ultra-crop-api > /dev/null 2>&1; then
            print_success "Found ultra-crop-api service"
            gcloud app services describe ultra-crop-api
        else
            print_warning "No ultra-crop-api service found in App Engine"
        fi
    else
        print_warning "App Engine is not enabled"
    fi
}

check_compute_engine() {
    print_info "Checking Compute Engine..."
    
    # Check for instances with ultra-crop in name
    INSTANCES=$(gcloud compute instances list --filter="name:ultra-crop" --format="value(name)" 2>/dev/null || echo "")
    
    if [ -n "$INSTANCES" ]; then
        print_success "Found Compute Engine instances:"
        gcloud compute instances list --filter="name:ultra-crop" --format="table(name,zone,machineType,status,EXTERNAL_IP)"
        
        for instance in $INSTANCES; do
            print_info "Checking instance: $instance"
            ZONE=$(gcloud compute instances describe $instance --format="value(zone)" 2>/dev/null | cut -d'/' -f9 || echo "")
            if [ -n "$ZONE" ]; then
                EXTERNAL_IP=$(gcloud compute instances describe $instance --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "")
                if [ -n "$EXTERNAL_IP" ]; then
                    print_success "External IP: $EXTERNAL_IP"
                    
                    # Test if port 5020 is open
                    if timeout 5 bash -c "</dev/tcp/$EXTERNAL_IP/5020" 2>/dev/null; then
                        print_success "Port 5020 is accessible"
                    else
                        print_warning "Port 5020 is not accessible"
                    fi
                fi
            fi
        done
    else
        print_warning "No Compute Engine instances found with 'ultra-crop' in name"
    fi
}

check_docker_images() {
    print_info "Checking Docker images in Container Registry..."
    
    # Check for ultra-crop images
    IMAGES=$(gcloud container images list --filter="name:ultra-crop" --format="value(name)" 2>/dev/null || echo "")
    
    if [ -n "$IMAGES" ]; then
        print_success "Found Docker images:"
        gcloud container images list --filter="name:ultra-crop" --format="table(name,creationTimestamp)"
    else
        print_warning "No Docker images found with 'ultra-crop' in name"
    fi
}

check_secrets() {
    print_info "Checking Secret Manager..."
    
    # Check for ultra-crop secrets
    SECRETS=$(gcloud secrets list --filter="name:ultra-crop" --format="value(name)" 2>/dev/null || echo "")
    
    if [ -n "$SECRETS" ]; then
        print_success "Found secrets:"
        gcloud secrets list --filter="name:ultra-crop" --format="table(name,createTime)"
    else
        print_warning "No secrets found with 'ultra-crop' in name"
    fi
}

show_help() {
    echo "Ultra Crop Recommender - Deployment Status Checker"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --cloud-run      Check only Cloud Run services"
    echo "  --gke           Check only GKE clusters"
    echo "  --app-engine    Check only App Engine"
    echo "  --compute       Check only Compute Engine"
    echo "  --images        Check only Docker images"
    echo "  --secrets       Check only Secret Manager"
    echo "  --all           Check all services (default)"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Check all services"
    echo "  $0 --cloud-run        # Check only Cloud Run"
    echo "  $0 --gke --images     # Check GKE and Docker images"
}

main() {
    print_header
    
    # Check if gcloud is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with Google Cloud. Please run:"
        echo "gcloud auth login"
        exit 1
    fi
    
    # Get current project
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ -z "$PROJECT_ID" ]; then
        print_error "No project set. Please run:"
        echo "gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
    
    print_success "Checking project: $PROJECT_ID"
    echo ""
    
    # Parse arguments
    CHECK_CLOUD_RUN=false
    CHECK_GKE=false
    CHECK_APP_ENGINE=false
    CHECK_COMPUTE=false
    CHECK_IMAGES=false
    CHECK_SECRETS=false
    CHECK_ALL=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cloud-run)
                CHECK_CLOUD_RUN=true
                CHECK_ALL=false
                shift
                ;;
            --gke)
                CHECK_GKE=true
                CHECK_ALL=false
                shift
                ;;
            --app-engine)
                CHECK_APP_ENGINE=true
                CHECK_ALL=false
                shift
                ;;
            --compute)
                CHECK_COMPUTE=true
                CHECK_ALL=false
                shift
                ;;
            --images)
                CHECK_IMAGES=true
                CHECK_ALL=false
                shift
                ;;
            --secrets)
                CHECK_SECRETS=true
                CHECK_ALL=false
                shift
                ;;
            --all)
                CHECK_ALL=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Run checks
    if [ "$CHECK_ALL" = true ] || [ "$CHECK_CLOUD_RUN" = true ]; then
        check_cloud_run
        echo ""
    fi
    
    if [ "$CHECK_ALL" = true ] || [ "$CHECK_GKE" = true ]; then
        check_gke
        echo ""
    fi
    
    if [ "$CHECK_ALL" = true ] || [ "$CHECK_APP_ENGINE" = true ]; then
        check_app_engine
        echo ""
    fi
    
    if [ "$CHECK_ALL" = true ] || [ "$CHECK_COMPUTE" = true ]; then
        check_compute_engine
        echo ""
    fi
    
    if [ "$CHECK_ALL" = true ] || [ "$CHECK_IMAGES" = true ]; then
        check_docker_images
        echo ""
    fi
    
    if [ "$CHECK_ALL" = true ] || [ "$CHECK_SECRETS" = true ]; then
        check_secrets
        echo ""
    fi
    
    print_success "Deployment check completed!"
}

# Run main function with all arguments
main "$@"
