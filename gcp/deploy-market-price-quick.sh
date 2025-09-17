#!/bin/bash

# Quick Deploy Market Price API to Google Cloud Run
echo "🚀 Quick Deploy: Market Price API to Google Cloud Run..."

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ No project ID set. Please run 'gcloud config set project YOUR_PROJECT_ID' first."
    exit 1
fi

echo "📋 Project: $PROJECT_ID"
echo "🌍 Region: us-central1"

# Build and deploy
echo "🔨 Building and deploying..."
gcloud run deploy market-price-api \
  --source ./backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 5004 \
  --memory 2Gi \
  --cpu 2 \
  --max-instances 10 \
  --min-instances 0 \
  --concurrency 100 \
  --timeout 300 \
  --set-env-vars FLASK_ENV=production,HOST=0.0.0.0,PORT=5004,DEBUG=false,API_VERSION=1.0.0

if [ $? -eq 0 ]; then
    echo "✅ Market Price API deployed successfully!"
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe market-price-api --region=us-central1 --format="value(status.url)")
    echo "🌐 Service URL: $SERVICE_URL"
    echo "📊 Health Check: $SERVICE_URL/health"
    echo "💰 Test: $SERVICE_URL/price/current?crop=Rice"
    
    # Test health
    echo "🔍 Testing service..."
    if curl -f "$SERVICE_URL/health" > /dev/null 2>&1; then
        echo "✅ Service is healthy!"
    else
        echo "⚠️ Service deployed but health check failed."
    fi
    
    echo "🎉 Deployment complete!"
else
    echo "❌ Deployment failed!"
    exit 1
fi
