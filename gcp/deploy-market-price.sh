#!/bin/bash

# Deploy Market Price API to Google Cloud Run
echo "🚀 Deploying Market Price API to Google Cloud Run..."

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

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install Google Cloud SDK first."
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_error "Not authenticated with gcloud. Please run 'gcloud auth login' first."
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    print_error "No project ID set. Please run 'gcloud config set project YOUR_PROJECT_ID' first."
    exit 1
fi

print_status "Using project: $PROJECT_ID"

# Set region
REGION="us-central1"
print_status "Using region: $REGION"

# Build and push image
print_status "Building Market Price API image..."
gcloud builds submit --config gcp/cloudbuild-market-price.yaml .

if [ $? -eq 0 ]; then
    print_status "✅ Market Price API deployed successfully!"
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe market-price-api --region=$REGION --format="value(status.url)")
    print_status "🌐 Service URL: $SERVICE_URL"
    print_status "📊 Health Check: $SERVICE_URL/health"
    print_status "💰 Market Prices: $SERVICE_URL/price/current?crop=Rice"
    print_status "🏪 Mandis: $SERVICE_URL/mandis"
    
    # Test the service
    print_status "Testing service health..."
    if curl -f "$SERVICE_URL/health" > /dev/null 2>&1; then
        print_status "✅ Service is healthy and responding!"
    else
        print_warning "⚠️ Service deployed but health check failed. Check logs with:"
        print_warning "gcloud run logs read market-price-api --region=$REGION"
    fi
    
    print_status "🎉 Market Price API deployment completed!"
    print_status "📝 To view logs: gcloud run logs read market-price-api --region=$REGION"
    print_status "🛑 To delete service: gcloud run services delete market-price-api --region=$REGION"
    
else
    print_error "❌ Deployment failed!"
    exit 1
fi
