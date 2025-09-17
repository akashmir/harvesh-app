# Ultra Crop Recommender - Windows PowerShell Deployment Script
# Deploy the Ultra Crop Recommender API to Google Cloud Run

param(
    [string]$ProjectId = "agrismart-app-1930c",
    [string]$Region = "us-central1",
    [string]$ServiceName = "ultra-crop-recommender-api",
    [string]$ImageName = "ultra-crop-recommender"
)

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-Header {
    Write-Host "$Blue"
    Write-Host "================================================================"
    Write-Host "    ULTRA CROP RECOMMENDER - GOOGLE CLOUD RUN DEPLOYMENT"
    Write-Host "================================================================"
    Write-Host "$Reset"
}

function Write-Success {
    param([string]$Message)
    Write-Host "$Green [SUCCESS] $Message$Reset"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "$Yellow [WARNING] $Message$Reset"
}

function Write-Error {
    param([string]$Message)
    Write-Host "$Red [ERROR] $Message$Reset"
}

function Write-Info {
    param([string]$Message)
    Write-Host "$Blue [INFO] $Message$Reset"
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check gcloud CLI
    try {
        $gcloudVersion = gcloud version 2>$null
        Write-Success "Google Cloud CLI is installed"
    }
    catch {
        Write-Error "Google Cloud CLI not found. Please install it first."
        exit 1
    }
    
    # Check Docker
    try {
        $dockerVersion = docker --version 2>$null
        Write-Success "Docker is installed"
    }
    catch {
        Write-Error "Docker not found. Please install Docker Desktop first."
        exit 1
    }
    
    # Check if authenticated
    try {
        $authInfo = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
        if ($authInfo) {
            Write-Success "Authenticated as: $authInfo"
        } else {
            Write-Error "Not authenticated. Please run 'gcloud auth login' first."
            exit 1
        }
    }
    catch {
        Write-Error "Authentication check failed. Please run 'gcloud auth login' first."
        exit 1
    }
}

function Set-Project {
    Write-Info "Setting up Google Cloud project..."
    
    gcloud config set project $ProjectId
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to set project. Please check your project ID."
        exit 1
    }
    
    Write-Success "Project set to: $ProjectId"
}

function Enable-APIs {
    Write-Info "Enabling required Google Cloud APIs..."
    
    $apis = @(
        "run.googleapis.com",
        "containerregistry.googleapis.com",
        "cloudbuild.googleapis.com",
        "secretmanager.googleapis.com"
    )
    
    foreach ($api in $apis) {
        Write-Info "Enabling $api..."
        gcloud services enable $api --quiet
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$api enabled"
        } else {
            Write-Warning "Failed to enable $api (may already be enabled)"
        }
    }
}

function Build-AndPush-Image {
    Write-Info "Building and pushing Docker image..."
    
    # Get commit SHA
    $commitSha = git rev-parse HEAD
    if ($LASTEXITCODE -ne 0) {
        $commitSha = "latest"
        Write-Warning "Could not get commit SHA, using 'latest'"
    }
    
    # Configure Docker for GCR
    Write-Info "Configuring Docker for Google Container Registry..."
    gcloud auth configure-docker --quiet
    
    # Build image
    Write-Info "Building Docker image..."
    $imageTag = "gcr.io/$ProjectId/$ImageName`:$commitSha"
    $latestTag = "gcr.io/$ProjectId/$ImageName`:latest"
    
    docker build -f ../backend/Dockerfile.ultra-crop-optimized -t $imageTag -t $latestTag ../backend
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed"
        exit 1
    }
    
    Write-Success "Docker image built successfully"
    
    # Push image
    Write-Info "Pushing image to Google Container Registry..."
    docker push $imageTag
    docker push $latestTag
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Image pushed successfully"
    } else {
        Write-Error "Failed to push image"
        exit 1
    }
}

function Deploy-To-CloudRun {
    Write-Info "Deploying to Google Cloud Run..."
    
    # Deploy the service
    gcloud run deploy $ServiceName `
        --image="gcr.io/$ProjectId/$ImageName`:latest" `
        --region=$Region `
        --platform=managed `
        --allow-unauthenticated `
        --port=5020 `
        --memory=4Gi `
        --cpu=4 `
        --max-instances=20 `
        --min-instances=1 `
        --concurrency=50 `
        --timeout=600 `
        --set-env-vars="ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5020,DEBUG=false,MODEL_PATH=/app/models,CACHE_TTL=3600" `
        --execution-environment=gen2
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Ultra Crop Recommender deployed successfully!"
        
        # Get service URL
        $serviceUrl = gcloud run services describe $ServiceName --region=$Region --format="value(status.url)"
        Write-Success "Service URL: $serviceUrl"
        
        # Test the deployment
        Write-Info "Testing deployment..."
        try {
            $healthResponse = Invoke-RestMethod -Uri "$serviceUrl/health" -Method GET -TimeoutSec 30
            Write-Success "Health check passed: $($healthResponse.status)"
        }
        catch {
            Write-Warning "Health check failed, but deployment completed: $($_.Exception.Message)"
        }
        
    } else {
        Write-Error "Deployment failed"
        exit 1
    }
}

# Main execution
Write-Header

Write-Info "Starting Ultra Crop Recommender deployment..."
Write-Info "Project ID: $ProjectId"
Write-Info "Region: $Region"
Write-Info "Service Name: $ServiceName"
Write-Info "Image Name: $ImageName"

Test-Prerequisites
Set-Project
Enable-APIs
Build-AndPush-Image
Deploy-To-CloudRun

Write-Success "Deployment completed successfully!"
Write-Info "You can now update your frontend configuration to use the new API URL."
