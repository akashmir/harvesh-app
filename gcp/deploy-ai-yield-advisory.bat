@echo off
REM AI Yield Advisory Production Deployment Script for Windows
REM Deploys Yield Prediction, Weather Integration, and Satellite Soil APIs to Google Cloud Run

setlocal enabledelayedexpansion

REM Configuration
set PROJECT_ID=harvest-enterprise-app-1930c
set REGION=us-central1
set SERVICE_ACCOUNT=ultra-crop-sa

echo ==========================================
echo AI Yield Advisory Production Deployment
echo ==========================================

REM Check prerequisites
echo [INFO] Checking prerequisites...

REM Check if gcloud is installed
where gcloud >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] gcloud CLI is not installed. Please install it first.
    exit /b 1
)

REM Check if docker is installed
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed. Please install it first.
    exit /b 1
)

REM Set project
gcloud config set project %PROJECT_ID%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to set project. Please check your gcloud authentication.
    exit /b 1
)

echo [SUCCESS] Prerequisites check passed

REM Create service account if it doesn't exist
echo [INFO] Setting up service account...
gcloud iam service-accounts describe %SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Creating service account...
    gcloud iam service-accounts create %SERVICE_ACCOUNT% --display-name="AI Yield Advisory Service Account" --description="Service account for AI Yield Advisory APIs"
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to create service account
        exit /b 1
    )
    
    REM Grant necessary permissions
    gcloud projects add-iam-policy-binding %PROJECT_ID% --member="serviceAccount:%SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to grant permissions to service account
        exit /b 1
    )
    
    echo [SUCCESS] Service account created
) else (
    echo [INFO] Service account already exists
)

REM Create secrets if they don't exist
echo [INFO] Setting up secrets...
for %%s in (openweather-api-key bhuvan-api-key secret-key) do (
    gcloud secrets describe %%s >nul 2>nul
    if %errorlevel% neq 0 (
        echo [WARNING] Secret %%s does not exist. Creating with placeholder value...
        echo your-%%s-value | gcloud secrets create %%s --data-file=-
        if %errorlevel% neq 0 (
            echo [ERROR] Failed to create secret %%s
            exit /b 1
        )
    ) else (
        echo [INFO] Secret %%s already exists
    )
)

echo [SUCCESS] Secrets setup completed

REM Deploy Yield Prediction API
echo ==========================================
echo [INFO] Deploying Yield Prediction API...
echo ==========================================

REM Create Dockerfile for Yield Prediction
(
echo FROM python:3.9-slim
echo.
echo WORKDIR /app
echo.
echo REM Install system dependencies
echo RUN apt-get update ^&^& apt-get install -y gcc g++ ^&^& rm -rf /var/lib/apt/lists/*
echo.
echo REM Copy requirements
echo COPY requirements.txt .
echo RUN pip install --no-cache-dir -r requirements.txt
echo.
echo REM Copy the specific API file
echo COPY yield_prediction_api.py .
echo.
echo REM Create models directory
echo RUN mkdir -p models
echo.
echo REM Expose port
echo EXPOSE 5003
echo.
echo REM Run the service
echo CMD ["python", "yield_prediction_api.py"]
) > backend\Dockerfile.yield-prediction

REM Build and push image
echo [INFO] Building and pushing Yield Prediction image...
docker build -f backend\Dockerfile.yield-prediction -t gcr.io\%PROJECT_ID%\ai-yield-advisory-yield-prediction:latest ./backend
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build Yield Prediction image
    exit /b 1
)

gcloud auth configure-docker --quiet
docker push gcr.io\%PROJECT_ID%\ai-yield-advisory-yield-prediction:latest
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push Yield Prediction image
    exit /b 1
)

REM Deploy to Cloud Run
echo [INFO] Deploying Yield Prediction to Cloud Run...
gcloud run deploy yield-prediction-api --image=gcr.io/%PROJECT_ID%/ai-yield-advisory-yield-prediction:latest --region=%REGION% --platform=managed --allow-unauthenticated --port=5003 --memory=2Gi --cpu=2 --max-instances=10 --min-instances=0 --concurrency=50 --timeout=300 --service-account=%SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com --set-env-vars="ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5003,DEBUG=false" --set-secrets="OPENWEATHER_API_KEY=openweather-api-key:latest,BHUVAN_API_KEY=bhuvan-api-key:latest,SECRET_KEY=secret-key:latest" --cpu-throttling --execution-environment=gen2 --project=%PROJECT_ID%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to deploy Yield Prediction API
    exit /b 1
)

REM Get service URL
for /f "tokens=*" %%i in ('gcloud run services describe yield-prediction-api --region=%REGION% --format="value(status.url)"') do set YIELD_PREDICTION_URL=%%i
echo [SUCCESS] Yield Prediction API deployed successfully!
echo Service URL: %YIELD_PREDICTION_URL%

REM Deploy Weather Integration API
echo ==========================================
echo [INFO] Deploying Weather Integration API...
echo ==========================================

REM Create Dockerfile for Weather Integration
(
echo FROM python:3.9-slim
echo.
echo WORKDIR /app
echo.
echo REM Install system dependencies
echo RUN apt-get update ^&^& apt-get install -y gcc g++ ^&^& rm -rf /var/lib/apt/lists/*
echo.
echo REM Copy requirements
echo COPY requirements.txt .
echo RUN pip install --no-cache-dir -r requirements.txt
echo.
echo REM Copy the specific API file
echo COPY weather_integration_api.py .
echo.
echo REM Expose port
echo EXPOSE 5005
echo.
echo REM Run the service
echo CMD ["python", "weather_integration_api.py"]
) > backend\Dockerfile.weather-integration

REM Build and push image
echo [INFO] Building and pushing Weather Integration image...
docker build -f backend\Dockerfile.weather-integration -t gcr.io\%PROJECT_ID%\ai-yield-advisory-weather-integration:latest ./backend
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build Weather Integration image
    exit /b 1
)

docker push gcr.io\%PROJECT_ID%\ai-yield-advisory-weather-integration:latest
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push Weather Integration image
    exit /b 1
)

REM Deploy to Cloud Run
echo [INFO] Deploying Weather Integration to Cloud Run...
gcloud run deploy weather-integration-api --image=gcr.io/%PROJECT_ID%/ai-yield-advisory-weather-integration:latest --region=%REGION% --platform=managed --allow-unauthenticated --port=5005 --memory=2Gi --cpu=2 --max-instances=10 --min-instances=0 --concurrency=50 --timeout=300 --service-account=%SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com --set-env-vars="ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5005,DEBUG=false" --set-secrets="OPENWEATHER_API_KEY=openweather-api-key:latest,BHUVAN_API_KEY=bhuvan-api-key:latest,SECRET_KEY=secret-key:latest" --cpu-throttling --execution-environment=gen2 --project=%PROJECT_ID%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to deploy Weather Integration API
    exit /b 1
)

REM Get service URL
for /f "tokens=*" %%i in ('gcloud run services describe weather-integration-api --region=%REGION% --format="value(status.url)"') do set WEATHER_INTEGRATION_URL=%%i
echo [SUCCESS] Weather Integration API deployed successfully!
echo Service URL: %WEATHER_INTEGRATION_URL%

REM Deploy Satellite Soil API
echo ==========================================
echo [INFO] Deploying Satellite Soil API...
echo ==========================================

REM Create Dockerfile for Satellite Soil
(
echo FROM python:3.9-slim
echo.
echo WORKDIR /app
echo.
echo REM Install system dependencies
echo RUN apt-get update ^&^& apt-get install -y gcc g++ ^&^& rm -rf /var/lib/apt/lists/*
echo.
echo REM Copy requirements
echo COPY requirements.txt .
echo RUN pip install --no-cache-dir -r requirements.txt
echo.
echo REM Copy the specific API file
echo COPY satellite_soil_api.py .
echo.
echo REM Expose port
echo EXPOSE 5006
echo.
echo REM Run the service
echo CMD ["python", "satellite_soil_api.py"]
) > backend\Dockerfile.satellite-soil

REM Build and push image
echo [INFO] Building and pushing Satellite Soil image...
docker build -f backend\Dockerfile.satellite-soil -t gcr.io\%PROJECT_ID%\ai-yield-advisory-satellite-soil:latest ./backend
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build Satellite Soil image
    exit /b 1
)

docker push gcr.io\%PROJECT_ID%\ai-yield-advisory-satellite-soil:latest
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push Satellite Soil image
    exit /b 1
)

REM Deploy to Cloud Run
echo [INFO] Deploying Satellite Soil to Cloud Run...
gcloud run deploy satellite-soil-api --image=gcr.io/%PROJECT_ID%/ai-yield-advisory-satellite-soil:latest --region=%REGION% --platform=managed --allow-unauthenticated --port=5006 --memory=2Gi --cpu=2 --max-instances=10 --min-instances=0 --concurrency=50 --timeout=300 --service-account=%SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com --set-env-vars="ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5006,DEBUG=false" --set-secrets="OPENWEATHER_API_KEY=openweather-api-key:latest,BHUVAN_API_KEY=bhuvan-api-key:latest,SECRET_KEY=secret-key:latest" --cpu-throttling --execution-environment=gen2 --project=%PROJECT_ID%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to deploy Satellite Soil API
    exit /b 1
)

REM Get service URL
for /f "tokens=*" %%i in ('gcloud run services describe satellite-soil-api --region=%REGION% --format="value(status.url)"') do set SATELLITE_SOIL_URL=%%i
echo [SUCCESS] Satellite Soil API deployed successfully!
echo Service URL: %SATELLITE_SOIL_URL%

REM Generate frontend configuration
echo [INFO] Generating frontend configuration...
(
echo # AI Yield Advisory Production Configuration
echo YIELD_PREDICTION_API_BASE_URL=%YIELD_PREDICTION_URL%
echo WEATHER_INTEGRATION_API_BASE_URL=%WEATHER_INTEGRATION_URL%
echo SATELLITE_SOIL_API_BASE_URL=%SATELLITE_SOIL_URL%
echo.
echo # Other production settings
echo DEBUG_MODE=false
echo API_TIMEOUT=30
echo API_RETRY_COUNT=3
echo API_RETRY_DELAY=2000
) > frontend\env.production

echo [SUCCESS] Frontend configuration generated

echo ==========================================
echo [SUCCESS] AI Yield Advisory production deployment completed!
echo ==========================================
echo [INFO] Service URLs:
echo   Yield Prediction: %YIELD_PREDICTION_URL%
echo   Weather Integration: %WEATHER_INTEGRATION_URL%
echo   Satellite Soil: %SATELLITE_SOIL_URL%
echo.
echo [INFO] Next steps:
echo 1. Update your Flutter app to use the production URLs
echo 2. Test the AI Yield Advisory feature in production
echo 3. Monitor the services in Google Cloud Console

pause
