# AI Yield Advisory Production Deployment Guide

This guide will help you deploy the AI Yield Advisory feature to production using Google Cloud Run.

## Prerequisites

1. **Google Cloud Account** with billing enabled
2. **Google Cloud CLI** (`gcloud`) installed and authenticated
3. **Docker** installed and running
4. **Git** (for getting commit SHA)

## Quick Deployment

### Option 1: Automated Script (Recommended)

#### For Linux/macOS:
```bash
chmod +x gcp/deploy-ai-yield-advisory.sh
./gcp/deploy-ai-yield-advisory.sh
```

#### For Windows:
```cmd
gcp\deploy-ai-yield-advisory.bat
```

### Option 2: Manual Deployment

#### Step 1: Set up Google Cloud Project
```bash
# Set your project ID
export PROJECT_ID="harvest-enterprise-app-1930c"
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
    --display-name="AI Yield Advisory Service Account" \
    --description="Service account for AI Yield Advisory APIs"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:ultra-crop-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

#### Step 3: Create Secrets
```bash
# Create secrets for API keys
echo "your-openweather-api-key" | gcloud secrets create openweather-api-key --data-file=-
echo "your-bhuvan-api-key" | gcloud secrets create bhuvan-api-key --data-file=-
echo "your-secret-key" | gcloud secrets create secret-key --data-file=-
```

## What Gets Deployed

The deployment script will create three Google Cloud Run services:

1. **Yield Prediction API** (Port 5003)
   - Service Name: `yield-prediction-api`
   - Handles yield predictions for crops
   - Uses ML models for accurate predictions

2. **Weather Integration API** (Port 5005)
   - Service Name: `weather-integration-api`
   - Provides real-time weather data
   - Integrates with OpenWeatherMap API

3. **Satellite Soil API** (Port 5006)
   - Service Name: `satellite-soil-api`
   - Provides soil data from satellite imagery
   - Integrates with Bhuvan and SoilGrids APIs

## Configuration

### Environment Variables
Each service is configured with:
- `ENVIRONMENT=production`
- `API_HOST=0.0.0.0`
- `DEBUG=false`
- Appropriate port (5003, 5005, or 5006)

### Resource Allocation
- **Memory**: 2Gi per service
- **CPU**: 2 cores per service
- **Max Instances**: 10 per service
- **Min Instances**: 0 per service
- **Concurrency**: 50 requests per instance
- **Timeout**: 300 seconds

## After Deployment

### 1. Update Frontend Configuration

The deployment script will generate a `frontend/env.production` file with the correct URLs. You need to:

1. Copy the URLs from the deployment output
2. Update `frontend/env.production` with the actual URLs
3. Update your Flutter app to use the production environment

### 2. Test the Services

Test each service individually:

```bash
# Test Yield Prediction API
curl https://your-yield-prediction-url/health

# Test Weather Integration API
curl https://your-weather-integration-url/health

# Test Satellite Soil API
curl https://your-satellite-soil-url/health
```

### 3. Test AI Yield Advisory Feature

1. Open your Flutter app
2. Navigate to the AI Yield & Advisory feature
3. Click "Get Advisory"
4. Verify it works without timeout errors

## Monitoring

### View Logs
```bash
# View logs for all services
gcloud run logs tail yield-prediction-api --region=us-central1
gcloud run logs tail weather-integration-api --region=us-central1
gcloud run logs tail satellite-soil-api --region=us-central1
```

### Monitor in Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to Cloud Run
3. Select your service
4. View metrics, logs, and health status

## Troubleshooting

### Common Issues

#### 1. Service Won't Start
- Check logs: `gcloud run logs tail [service-name] --region=us-central1`
- Verify environment variables are set correctly
- Ensure secrets are properly configured

#### 2. Timeout Issues
- Check if external APIs (OpenWeatherMap, Bhuvan) are accessible
- Verify API keys are valid
- Check service resource allocation

#### 3. Authentication Issues
- Verify service account permissions
- Check secret access permissions
- Ensure API keys are valid

### Debug Commands

```bash
# Check service status
gcloud run services describe yield-prediction-api --region=us-central1
gcloud run services describe weather-integration-api --region=us-central1
gcloud run services describe satellite-soil-api --region=us-central1

# View recent logs
gcloud run logs read yield-prediction-api --region=us-central1 --limit=50

# Check secrets
gcloud secrets list
```

## Cost Optimization

### Resource Management
- Services are configured with `min-instances=0` to scale to zero when not in use
- CPU throttling is enabled to reduce costs during idle periods
- Memory and CPU allocation is optimized for the workload

### Monitoring Costs
- Monitor usage in Google Cloud Console
- Set up billing alerts
- Review and adjust resource allocation as needed

## Security

### Best Practices
- Service accounts use least privilege principle
- API keys are stored in Google Secret Manager
- Services are deployed with HTTPS only
- No sensitive data is logged

### Network Security
- Services are deployed with public access (allow-unauthenticated)
- Consider implementing authentication if needed
- Use VPC connector for private network access if required

## Updates and Maintenance

### Updating Services
1. Make changes to the API files
2. Run the deployment script again
3. The script will build new images and deploy updates
4. Test the updated services

### Rolling Back
```bash
# List revisions
gcloud run revisions list --service=yield-prediction-api --region=us-central1

# Route traffic to previous revision
gcloud run services update-traffic yield-prediction-api \
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
