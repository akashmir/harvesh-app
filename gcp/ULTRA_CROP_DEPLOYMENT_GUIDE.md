# Ultra Crop Recommender - Google Cloud Run Deployment Guide

This guide provides step-by-step instructions for deploying the Ultra Crop Recommender API to Google Cloud Run using Docker.

## Prerequisites

### 1. Google Cloud Setup
- Google Cloud account with billing enabled
- Google Cloud CLI (`gcloud`) installed and authenticated
- Docker installed and running
- Git (for getting commit SHA)

### 2. Required APIs
The following Google Cloud APIs must be enabled:
- Cloud Run API
- Container Registry API
- Cloud Build API
- Secret Manager API

### 3. Permissions
Your Google Cloud account needs the following roles:
- Cloud Run Admin
- Storage Admin (for Container Registry)
- Secret Manager Admin
- Service Account Admin

## Quick Deployment

### Option 1: Automated Script (Recommended)

#### For Linux/macOS:
```bash
chmod +x gcp/deploy-ultra-crop-optimized.sh
./gcp/deploy-ultra-crop-optimized.sh
```

#### For Windows:
```cmd
gcp\deploy-ultra-crop-optimized.bat
```

### Option 2: Manual Deployment

#### Step 1: Set up Google Cloud Project
```bash
# Set your project ID
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable cloudbuild.googleapis.com \
    run.googleapis.com \
    containerregistry.googleapis.com \
    secretmanager.googleapis.com
```

#### Step 2: Create Service Account
```bash
# Create service account
gcloud iam service-accounts create ultra-crop-sa \
    --display-name="Ultra Crop Recommender Service Account" \
    --description="Service account for Ultra Crop Recommender API"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:ultra-crop-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

#### Step 3: Create Secrets
```bash
# Create secrets for API keys
echo "your-openweather-api-key" | gcloud secrets create openweather-api-key --data-file=-
echo "your-google-earth-engine-key" | gcloud secrets create google-earth-engine-key --data-file=-
echo "your-bhuvan-api-key" | gcloud secrets create bhuvan-api-key --data-file=-
echo "your-secret-key" | gcloud secrets create secret-key --data-file=-
```

#### Step 4: Build and Push Docker Image
```bash
# Get commit SHA
COMMIT_SHA=$(git rev-parse HEAD)

# Build the image
docker build -f backend/Dockerfile.ultra-crop-optimized \
    -t gcr.io/$PROJECT_ID/ultra-crop-recommender:$COMMIT_SHA \
    -t gcr.io/$PROJECT_ID/ultra-crop-recommender:latest \
    ./backend

# Configure Docker authentication
gcloud auth configure-docker

# Push the image
docker push gcr.io/$PROJECT_ID/ultra-crop-recommender:$COMMIT_SHA
docker push gcr.io/$PROJECT_ID/ultra-crop-recommender:latest
```

#### Step 5: Deploy to Cloud Run
```bash
gcloud run deploy ultra-crop-recommender-api \
    --image=gcr.io/$PROJECT_ID/ultra-crop-recommender:$COMMIT_SHA \
    --region=us-central1 \
    --platform=managed \
    --allow-unauthenticated \
    --port=5020 \
    --memory=4Gi \
    --cpu=4 \
    --max-instances=20 \
    --min-instances=1 \
    --concurrency=50 \
    --timeout=600 \
    --service-account=ultra-crop-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --set-env-vars="ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5020,DEBUG=false,MODEL_PATH=/app/models,CACHE_TTL=3600,ULTRA_REQUEST_TIMEOUT=10.0" \
    --set-secrets="OPENWEATHER_API_KEY=openweather-api-key:latest,GOOGLE_EARTH_ENGINE_KEY=google-earth-engine-key:latest,BHUVAN_API_KEY=bhuvan-api-key:latest,SECRET_KEY=secret-key:latest" \
    --cpu-throttling \
    --execution-environment=gen2
```

## Configuration

### Environment Variables
- `ENVIRONMENT`: Set to "production"
- `API_HOST`: Set to "0.0.0.0" for Cloud Run
- `API_PORT`: Set to "5020"
- `DEBUG`: Set to "false" for production
- `MODEL_PATH`: Path to ML models directory
- `CACHE_TTL`: Cache time-to-live in seconds
- `ULTRA_REQUEST_TIMEOUT`: Timeout for external API requests

### Secrets
The following secrets are required:
- `OPENWEATHER_API_KEY`: OpenWeatherMap API key
- `GOOGLE_EARTH_ENGINE_KEY`: Google Earth Engine API key
- `BHUVAN_API_KEY`: Bhuvan API key
- `SECRET_KEY`: Flask secret key

### Resource Allocation
- **Memory**: 4Gi (recommended for ML models)
- **CPU**: 4 cores
- **Max Instances**: 20
- **Min Instances**: 1
- **Concurrency**: 50 requests per instance
- **Timeout**: 600 seconds

## Testing the Deployment

### 1. Health Check
```bash
curl https://your-service-url/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000000",
  "version": "1.0.0",
  "ml_models_loaded": true,
  "crop_database_loaded": true
}
```

### 2. API Test
```bash
curl -X POST https://your-service-url/ultra-recommend \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 28.6139,
    "longitude": 77.2090,
    "farm_size": 1.0,
    "irrigation_type": "drip"
  }'
```

### 3. Quick Recommendation Test
```bash
curl -X POST https://your-service-url/ultra-recommend/quick \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 28.6139,
    "longitude": 77.2090
  }'
```

## Monitoring and Logs

### View Logs
```bash
gcloud run logs tail ultra-crop-recommender-api --region=us-central1
```

### Monitor Metrics
- Go to Google Cloud Console
- Navigate to Cloud Run
- Select your service
- View metrics in the "Metrics" tab

### Health Monitoring
- Set up uptime checks in Google Cloud Monitoring
- Configure alerts for service failures
- Monitor response times and error rates

## Troubleshooting

### Common Issues

#### 1. Service Won't Start
- Check logs: `gcloud run logs tail ultra-crop-recommender-api --region=us-central1`
- Verify environment variables are set correctly
- Ensure secrets are properly configured

#### 2. Memory Issues
- Increase memory allocation if ML models fail to load
- Check if models are too large for the container

#### 3. Timeout Issues
- Increase timeout value for long-running requests
- Optimize ML model loading
- Check external API response times

#### 4. Authentication Issues
- Verify service account permissions
- Check secret access permissions
- Ensure API keys are valid

### Debug Commands

```bash
# Check service status
gcloud run services describe ultra-crop-recommender-api --region=us-central1

# View recent logs
gcloud run logs read ultra-crop-recommender-api --region=us-central1 --limit=50

# Check secrets
gcloud secrets list

# Test secret access
gcloud secrets versions access latest --secret="openweather-api-key"
```

## Scaling and Performance

### Auto-scaling
- Cloud Run automatically scales based on traffic
- Configure min/max instances based on expected load
- Monitor CPU and memory usage

### Performance Optimization
- Use Cloud Run's second generation execution environment
- Enable CPU throttling for cost optimization
- Implement caching for frequently accessed data
- Optimize ML model loading and inference

### Cost Optimization
- Set appropriate min/max instances
- Use CPU throttling when idle
- Monitor resource usage and adjust allocation
- Consider using preemptible instances for non-critical workloads

## Security

### Best Practices
- Use least privilege principle for service accounts
- Rotate API keys regularly
- Enable audit logging
- Use HTTPS only
- Implement proper error handling

### Network Security
- Configure VPC connector if needed
- Use private Google access for internal services
- Implement proper CORS policies

## Updates and Maintenance

### Updating the Service
1. Build new Docker image with updated code
2. Push to Container Registry
3. Deploy new revision to Cloud Run
4. Test the new deployment
5. Route traffic to new revision

### Rolling Back
```bash
# List revisions
gcloud run revisions list --service=ultra-crop-recommender-api --region=us-central1

# Route traffic to previous revision
gcloud run services update-traffic ultra-crop-recommender-api \
    --to-revisions=REVISION_NAME=100 \
    --region=us-central1
```

## Support

For issues and questions:
1. Check the logs first
2. Review this deployment guide
3. Check Google Cloud Run documentation
4. Contact the development team

## Additional Resources

- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Google Cloud Secret Manager](https://cloud.google.com/secret-manager/docs)
