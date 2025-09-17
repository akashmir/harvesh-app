@echo off
REM Ultra Crop Recommender - Optimized Deployment Script for Windows
REM This script deploys the ultra crop recommender API to Google Cloud Run

setlocal enabledelayedexpansion

REM Configuration
set PROJECT_ID=
set REGION=us-central1
set SERVICE_NAME=ultra-crop-recommender-api
set IMAGE_NAME=ultra-crop-recommender

echo ==========================================
echo   Ultra Crop Recommender Deployment
echo ==========================================

REM Check if gcloud is installed
where gcloud >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] gcloud CLI is not installed. Please install it first.
    exit /b 1
)

REM Get project ID
if "%PROJECT_ID%"=="" (
    for /f "tokens=*" %%i in ('gcloud config get-value project 2^>nul') do set PROJECT_ID=%%i
    if "%PROJECT_ID%"=="" (
        echo [ERROR] No project ID set. Please set it with 'gcloud config set project YOUR_PROJECT_ID'
        exit /b 1
    )
)
echo [INFO] Using project: %PROJECT_ID%

REM Enable required APIs
echo [INFO] Enabling required Google Cloud APIs...
gcloud services enable cloudbuild.googleapis.com run.googleapis.com containerregistry.googleapis.com secretmanager.googleapis.com --project=%PROJECT_ID%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to enable APIs
    exit /b 1
)
echo [SUCCESS] APIs enabled successfully

REM Create service account if it doesn't exist
echo [INFO] Checking service account...
gcloud iam service-accounts describe ultra-crop-sa@%PROJECT_ID%.iam.gserviceaccount.com --project=%PROJECT_ID% >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Creating service account...
    gcloud iam service-accounts create ultra-crop-sa --display-name="Ultra Crop Recommender Service Account" --description="Service account for Ultra Crop Recommender API" --project=%PROJECT_ID%
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to create service account
        exit /b 1
    )
    
    REM Grant necessary permissions
    gcloud projects add-iam-policy-binding %PROJECT_ID% --member="serviceAccount:ultra-crop-sa@%PROJECT_ID%.iam.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
    echo [SUCCESS] Service account created and configured
) else (
    echo [SUCCESS] Service account already exists
)

REM Create secrets if they don't exist
echo [INFO] Checking secrets...
set secrets=openweather-api-key google-earth-engine-key bhuvan-api-key secret-key
for %%s in (%secrets%) do (
    gcloud secrets describe %%s --project=%PROJECT_ID% >nul 2>nul
    if !errorlevel! neq 0 (
        echo [WARNING] Secret %%s does not exist. Creating placeholder...
        echo your-%%s-here | gcloud secrets create %%s --data-file=- --project=%PROJECT_ID%
        echo [SUCCESS] Placeholder secret %%s created. Please update with real values.
    ) else (
        echo [SUCCESS] Secret %%s already exists
    )
)

REM Build Docker image
echo [INFO] Building Docker image...
set COMMIT_SHA=latest
for /f "tokens=*" %%i in ('git rev-parse HEAD 2^>nul') do set COMMIT_SHA=%%i

docker build -f backend/Dockerfile.ultra-crop-optimized -t gcr.io/%PROJECT_ID%/%IMAGE_NAME%:%COMMIT_SHA% -t gcr.io/%PROJECT_ID%/%IMAGE_NAME%:latest ./backend
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build Docker image
    exit /b 1
)
echo [SUCCESS] Docker image built successfully

REM Configure Docker to use gcloud as a credential helper
gcloud auth configure-docker --quiet

REM Push the image
echo [INFO] Pushing Docker image to Container Registry...
docker push gcr.io/%PROJECT_ID%/%IMAGE_NAME%:%COMMIT_SHA%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push Docker image
    exit /b 1
)
docker push gcr.io/%PROJECT_ID%/%IMAGE_NAME%:latest
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push Docker image
    exit /b 1
)
echo [SUCCESS] Docker image pushed successfully

REM Deploy to Cloud Run
echo [INFO] Deploying to Cloud Run...
gcloud run deploy %SERVICE_NAME% --image=gcr.io/%PROJECT_ID%/%IMAGE_NAME%:%COMMIT_SHA% --region=%REGION% --platform=managed --allow-unauthenticated --port=5020 --memory=4Gi --cpu=4 --max-instances=20 --min-instances=1 --concurrency=50 --timeout=600 --service-account=ultra-crop-sa@%PROJECT_ID%.iam.gserviceaccount.com --set-env-vars="ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5020,DEBUG=false,MODEL_PATH=/app/models,CACHE_TTL=3600,ULTRA_REQUEST_TIMEOUT=10.0" --set-secrets="OPENWEATHER_API_KEY=openweather-api-key:latest,GOOGLE_EARTH_ENGINE_KEY=google-earth-engine-key:latest,BHUVAN_API_KEY=bhuvan-api-key:latest,SECRET_KEY=secret-key:latest" --cpu-throttling --execution-environment=gen2 --project=%PROJECT_ID%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to deploy to Cloud Run
    exit /b 1
)
echo [SUCCESS] Deployment completed successfully

REM Get service URL
echo [INFO] Getting service URL...
for /f "tokens=*" %%i in ('gcloud run services describe %SERVICE_NAME% --region=%REGION% --platform=managed --format="value(status.url)" --project=%PROJECT_ID%') do set SERVICE_URL=%%i
echo [SUCCESS] Service deployed at: %SERVICE_URL%
echo [INFO] Health check: %SERVICE_URL%/health
echo [INFO] API endpoint: %SERVICE_URL%/ultra-recommend

REM Test the deployment
echo [INFO] Testing deployment...
curl -f "%SERVICE_URL%/health" >nul 2>nul
if %errorlevel% equ 0 (
    echo [SUCCESS] Health check passed
) else (
    echo [WARNING] Health check failed - service may still be starting up
)

echo ==========================================
echo [SUCCESS] Deployment completed successfully!
echo ==========================================
echo.
echo Next steps:
echo 1. Update secrets with real API keys:
echo    gcloud secrets versions add openweather-api-key --data-file=-
echo 2. Test the API: %SERVICE_URL%/health
echo 3. Monitor logs: gcloud run logs tail %SERVICE_NAME% --region=%REGION%
echo.

pause
