# Ultra Crop Recommender - Google Cloud Platform Deployment

This directory contains all the necessary files and scripts to deploy the Ultra Crop Recommender system to Google Cloud Platform.

## 🚀 Quick Start

### Prerequisites

1. **Google Cloud CLI** - [Install Guide](https://cloud.google.com/sdk/docs/install)
2. **Docker** - [Install Guide](https://docs.docker.com/get-docker/)
3. **Google Cloud Project** with billing enabled

### 1. Authentication

```bash
# Login to Google Cloud
gcloud auth login

# Set your project ID
export PROJECT_ID=your-project-id
gcloud config set project $PROJECT_ID
```

### 2. Deploy to Cloud Run (Recommended)

**Linux/Mac:**
```bash
# Setup GCP project
./gcp/deploy-gcp.sh setup

# Deploy to Cloud Run
./gcp/deploy-gcp.sh deploy cloudrun
```

**Windows:**
```cmd
# Setup GCP project
gcp\deploy-gcp.bat your-project-id setup

# Deploy to Cloud Run
gcp\deploy-gcp.bat your-project-id deploy
```

### 3. Deploy to Google Kubernetes Engine (GKE)

**Linux/Mac:**
```bash
# Deploy to GKE
./gcp/deploy-gcp.sh deploy gke
```

### 4. Deploy to App Engine

**Linux/Mac:**
```bash
# Deploy to App Engine
./gcp/deploy-gcp.sh deploy appengine
```

## 📁 File Structure

```
gcp/
├── README.md                    # This file
├── deploy-gcp.sh               # Linux/Mac deployment script
├── deploy-gcp.bat              # Windows deployment script
├── cloudbuild.yaml             # Cloud Build configuration
├── backend-cloudrun.yaml       # Cloud Run backend service
├── frontend-cloudrun.yaml      # Cloud Run frontend service
└── k8s/                        # Kubernetes manifests
    ├── namespace.yaml          # Kubernetes namespace
    ├── configmap.yaml          # Configuration
    ├── secret.yaml             # Secrets
    ├── backend-deployment.yaml # Backend deployment
    ├── frontend-deployment.yaml# Frontend deployment
    ├── services.yaml           # Kubernetes services
    └── ingress.yaml            # Ingress configuration
```

## 🔧 Configuration

### Environment Variables

Before deploying, update the following in your Google Cloud Secret Manager:

1. **OpenWeather API Key**
   ```bash
   echo "your_actual_api_key" | gcloud secrets create openweather-api-key --data-file=-
   ```

2. **Google Maps API Key**
   ```bash
   echo "your_actual_api_key" | gcloud secrets create google-maps-api-key --data-file=-
   ```

3. **Soil Grids API Key**
   ```bash
   echo "your_actual_api_key" | gcloud secrets create soil-grids-api-key --data-file=-
   ```

4. **Secret Key**
   ```bash
   echo "your_secure_secret_key" | gcloud secrets create secret-key --data-file=-
   ```

### Project Configuration

Update the following in the deployment files:

1. **Project ID**: Replace `PROJECT_ID` with your actual project ID
2. **Domain**: Update `yourdomain.com` in ingress.yaml with your domain
3. **Region**: Change `us-central1` to your preferred region

## 🌐 Deployment Options

### 1. Cloud Run (Serverless)

**Pros:**
- Fully managed
- Auto-scaling
- Pay per use
- No server management

**Cons:**
- Cold starts
- Limited to HTTP requests
- 15-minute timeout limit

**Best for:** Production workloads with variable traffic

### 2. Google Kubernetes Engine (GKE)

**Pros:**
- Full control over infrastructure
- Long-running processes
- Complex networking
- Custom resource configurations

**Cons:**
- More complex setup
- Higher costs for small workloads
- Requires Kubernetes knowledge

**Best for:** Complex applications requiring custom configurations

### 3. App Engine

**Pros:**
- Fully managed
- Automatic scaling
- Built-in monitoring
- Easy deployment

**Cons:**
- Limited to supported runtimes
- Less control over infrastructure
- Platform-specific constraints

**Best for:** Simple web applications

## 🔍 Monitoring and Logging

### Cloud Run

```bash
# View logs
gcloud logs read --service=ultra-crop-api --limit=50

# View metrics
gcloud run services describe ultra-crop-api --region=us-central1
```

### GKE

```bash
# View pods
kubectl get pods -n ultra-crop

# View logs
kubectl logs -f deployment/ultra-crop-api -n ultra-crop

# View services
kubectl get services -n ultra-crop
```

### App Engine

```bash
# View logs
gcloud app logs tail -s ultra-crop-api

# View versions
gcloud app versions list
```

## 🔒 Security

### IAM Roles

The deployment script creates a service account with the following roles:

- `roles/cloudsql.client` - Database access
- `roles/secretmanager.secretAccessor` - Secret access

### Network Security

- Cloud Run: Automatic HTTPS, no public IPs
- GKE: Private cluster option, network policies
- App Engine: Automatic HTTPS, built-in security

### Secrets Management

All sensitive data is stored in Google Secret Manager:

- API keys
- Database passwords
- JWT secrets

## 📊 Scaling

### Cloud Run

```bash
# Update scaling parameters
gcloud run services update ultra-crop-api \
  --region=us-central1 \
  --max-instances=20 \
  --min-instances=2
```

### GKE

```bash
# Scale deployments
kubectl scale deployment ultra-crop-api --replicas=5 -n ultra-crop

# Enable horizontal pod autoscaling
kubectl autoscale deployment ultra-crop-api --min=2 --max=10 -n ultra-crop
```

## 🛠️ Troubleshooting

### Common Issues

**1. Authentication Errors**
```bash
# Re-authenticate
gcloud auth login
gcloud auth application-default login
```

**2. Permission Denied**
```bash
# Check IAM roles
gcloud projects get-iam-policy $PROJECT_ID
```

**3. Image Pull Errors**
```bash
# Check if images exist
gcloud container images list --repository=gcr.io/$PROJECT_ID
```

**4. Service Not Starting**
```bash
# Check logs
gcloud logs read --service=ultra-crop-api --limit=100
```

### Debug Commands

```bash
# Check project configuration
gcloud config list

# Check enabled APIs
gcloud services list --enabled

# Check quotas
gcloud compute project-info describe --project=$PROJECT_ID
```

## 💰 Cost Optimization

### Cloud Run

- Use appropriate memory/CPU settings
- Set minimum instances to 0 for development
- Use request-based pricing

### GKE

- Use preemptible instances for non-production
- Right-size node pools
- Enable cluster autoscaling

### App Engine

- Use automatic scaling
- Optimize instance classes
- Use flexible environment for better control

## 🔄 CI/CD Integration

### Cloud Build

The `cloudbuild.yaml` file can be used with Cloud Build for automated deployments:

```bash
# Trigger build
gcloud builds submit --config=gcp/cloudbuild.yaml .
```

### GitHub Actions

Create `.github/workflows/deploy-gcp.yml`:

```yaml
name: Deploy to GCP
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: google-github-actions/setup-gcloud@v0
        with:
          service_account_key: ${{ secrets.GCP_SA_KEY }}
          project_id: ${{ secrets.GCP_PROJECT_ID }}
      - run: ./gcp/deploy-gcp.sh deploy cloudrun
```

## 📞 Support

For issues with GCP deployment:

1. Check the [Google Cloud Documentation](https://cloud.google.com/docs)
2. Review the [Cloud Run Troubleshooting Guide](https://cloud.google.com/run/docs/troubleshooting)
3. Check the [GKE Troubleshooting Guide](https://cloud.google.com/kubernetes-engine/docs/troubleshooting)

## 🎯 Next Steps

1. **Set up monitoring** with Cloud Monitoring
2. **Configure alerts** for critical metrics
3. **Set up backup** for persistent data
4. **Implement CI/CD** pipeline
5. **Configure custom domain** and SSL
6. **Set up load balancing** for high availability
