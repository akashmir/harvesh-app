# Ultra Crop Recommender - Google Cloud Run Deployment Guide

This guide provides step-by-step instructions for deploying the Ultra Crop Recommender API to Google Cloud Run.

## Prerequisites

### 1. Google Cloud Account
- A Google Cloud Platform account with billing enabled
- A GCP project with the following APIs enabled:
  - Cloud Run API
  - Cloud Build API
  - Secret Manager API
  - Container Registry API

### 2. Local Development Environment
- Google Cloud CLI installed and configured
- Docker installed and running
- Git (for cloning the repository)

### 3. API Keys Required
- OpenWeather API key (for weather data)
- Google Earth Engine API key (for satellite data)
- Bhuvan API key (for Indian satellite data)

## Quick Start

### Option 1: Using the Deployment Script (Recommended)

#### For Linux/macOS:
```bash
# Set your project ID
export PROJECT_ID=your-project-id

# Make the script executable
chmod +x gcp/deploy-ultra-crop-recommender.sh

# Setup GCP project and APIs
./gcp/deploy-ultra-crop-recommender.sh setup

# Deploy the application
./gcp/deploy-ultra-crop-recommender.sh deploy

# Test the deployment
./gcp/deploy-ultra-crop-recommender.sh test
```

#### For Windows:
```cmd
REM Set your project ID
set PROJECT_ID=your-project-id

REM Setup GCP project and APIs
gcp\deploy-ultra-crop-recommender.bat setup

REM Deploy the application
gcp\deploy-ultra-crop-recommender.bat deploy

REM Test the deployment
gcp\deploy-ultra-crop-recommender.bat test
```

### Option 2: Manual Deployment

#### Step 1: Setup Google Cloud Project

```bash
# Set your project ID
export PROJECT_ID=your-project-id

# Configure gcloud
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable cloudbuild.googleapis.com run.googleapis.com secretmanager.googleapis.com container.googleapis.com
```

#### Step 2: Create Service Account

```bash
# Create service account
gcloud iam service-accounts create ultra-crop-sa \
    --display-name="Ultra Crop Recommender Service Account" \
    --description="Service account for Ultra Crop Recommender application"

# Grant necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:ultra-crop-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:ultra-crop-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"
```

#### Step 3: Setup Secrets

```bash
# Create secrets in Secret Manager
echo -n "your_openweather_api_key_here" | gcloud secrets create openweather-api-key --data-file=-
echo -n "your_google_earth_engine_key_here" | gcloud secrets create google-earth-engine-key --data-file=-
echo -n "your_bhuvan_api_key_here" | gcloud secrets create bhuvan-api-key --data-file=-
echo -n "ultra-crop-secret-key-$(date +%s)" | gcloud secrets create secret-key --data-file=-
```

#### Step 4: Build and Push Docker Image

```bash
# Configure Docker for GCR
gcloud auth configure-docker

# Build the image
docker build -f backend/Dockerfile.cloudrun -t gcr.io/$PROJECT_ID/ultra-crop-recommender:latest ./backend

# Push the image
docker push gcr.io/$PROJECT_ID/ultra-crop-recommender:latest
```

#### Step 5: Deploy to Cloud Run

```bash
# Deploy the service
gcloud run deploy ultra-crop-recommender-api \
    --image gcr.io/$PROJECT_ID/ultra-crop-recommender:latest \
    --region us-central1 \
    --platform managed \
    --allow-unauthenticated \
    --port 5020 \
    --memory 4Gi \
    --cpu 4 \
    --max-instances 20 \
    --min-instances 1 \
    --concurrency 50 \
    --timeout 600 \
    --service-account ultra-crop-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --set-env-vars "ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5020,DEBUG=false,MODEL_PATH=/app/models,CACHE_TTL=3600,ULTRA_REQUEST_TIMEOUT=10.0" \
    --set-secrets "OPENWEATHER_API_KEY=openweather-api-key:latest,GOOGLE_EARTH_ENGINE_KEY=google-earth-engine-key:latest,BHUVAN_API_KEY=bhuvan-api-key:latest,SECRET_KEY=secret-key:latest"
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Environment mode | `production` |
| `API_HOST` | Host to bind to | `0.0.0.0` |
| `API_PORT` | Port to listen on | `5020` |
| `DEBUG` | Debug mode | `false` |
| `MODEL_PATH` | Path to ML models | `/app/models` |
| `CACHE_TTL` | Cache TTL in seconds | `3600` |
| `ULTRA_REQUEST_TIMEOUT` | External API timeout | `10.0` |

### Secrets

| Secret Name | Description |
|-------------|-------------|
| `openweather-api-key` | OpenWeather API key for weather data |
| `google-earth-engine-key` | Google Earth Engine API key for satellite data |
| `bhuvan-api-key` | Bhuvan API key for Indian satellite data |
| `secret-key` | Application secret key |

### Resource Configuration

- **CPU**: 4 vCPUs
- **Memory**: 4 GiB
- **Max Instances**: 20
- **Min Instances**: 1
- **Concurrency**: 50 requests per instance
- **Timeout**: 600 seconds

## API Endpoints

Once deployed, the service will be available at:
- **Base URL**: `https://ultra-crop-recommender-api-<hash>-uc.a.run.app`
- **Health Check**: `GET /health`
- **API Documentation**: `GET /docs`
- **Ultra Recommendation**: `POST /ultra-recommend`

### Example API Call

```bash
curl -X POST "https://your-service-url/ultra-recommend" \
  -H "Content-Type: application/json" \
  -d '{
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
```

## Monitoring and Logs

### View Logs
```bash
# View recent logs
gcloud run logs read ultra-crop-recommender-api --region=us-central1 --limit=50

# Follow logs in real-time
gcloud run logs tail ultra-crop-recommender-api --region=us-central1
```

### Monitor Performance
- Use Google Cloud Console to monitor:
  - Request count and latency
  - Error rates
  - Resource utilization
  - Instance count and scaling

## Troubleshooting

### Common Issues

1. **Service fails to start**
   - Check logs for error messages
   - Verify all secrets are properly configured
   - Ensure ML models are present in the container

2. **High memory usage**
   - Increase memory allocation
   - Check for memory leaks in the application
   - Optimize ML model loading

3. **Slow response times**
   - Increase CPU allocation
   - Check external API response times
   - Optimize database queries

4. **Authentication errors**
   - Verify service account permissions
   - Check secret configuration
   - Ensure API keys are valid

### Debug Commands

```bash
# Check service status
gcloud run services describe ultra-crop-recommender-api --region=us-central1

# View service configuration
gcloud run services describe ultra-crop-recommender-api --region=us-central1 --format="export"

# Test health endpoint
curl -f "https://your-service-url/health"

# Check service logs
gcloud run logs read ultra-crop-recommender-api --region=us-central1 --limit=100
```

## Scaling and Performance

### Auto-scaling
The service is configured to automatically scale based on:
- Request volume
- CPU utilization
- Memory usage

### Performance Optimization
- ML models are loaded once at startup
- Caching is implemented for external API calls
- Database connections are pooled
- Response compression is enabled

## Security

### Network Security
- Service is deployed with HTTPS by default
- No unauthenticated access to sensitive endpoints
- Secrets are managed through Google Secret Manager

### Data Protection
- All API keys are stored as secrets
- Database connections use encrypted channels
- Input validation and sanitization

## Cost Optimization

### Resource Management
- Minimum instances set to 1 to avoid cold starts
- Maximum instances limited to 20
- CPU and memory allocated based on actual needs

### Monitoring Costs
- Use Google Cloud Console to monitor spending
- Set up billing alerts
- Review resource utilization regularly

## Cleanup

To remove all resources:

```bash
# Delete Cloud Run service
gcloud run services delete ultra-crop-recommender-api --region=us-central1

# Delete Docker images
gcloud container images delete gcr.io/$PROJECT_ID/ultra-crop-recommender:latest

# Delete secrets (optional)
gcloud secrets delete openweather-api-key
gcloud secrets delete google-earth-engine-key
gcloud secrets delete bhuvan-api-key
gcloud secrets delete secret-key

# Delete service account (optional)
gcloud iam service-accounts delete ultra-crop-sa@$PROJECT_ID.iam.gserviceaccount.com
```

## Support

For issues and questions:
1. Check the logs first
2. Review this documentation
3. Check the main project README
4. Create an issue in the project repository

## Additional Resources

- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Run Pricing](https://cloud.google.com/run/pricing)
- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [Container Registry Documentation](https://cloud.google.com/container-registry/docs)
