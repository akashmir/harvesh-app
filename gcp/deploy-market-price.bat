@echo off
REM Deploy Market Price API to Google Cloud Run (Windows)
echo 🚀 Deploying Market Price API to Google Cloud Run...

REM Check if gcloud is installed
gcloud --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] gcloud CLI is not installed. Please install Google Cloud SDK first.
    exit /b 1
)

REM Check if user is authenticated
gcloud auth list --filter=status:ACTIVE --format="value(account)" >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Not authenticated with gcloud. Please run 'gcloud auth login' first.
    exit /b 1
)

REM Get project ID
for /f "tokens=*" %%i in ('gcloud config get-value project') do set PROJECT_ID=%%i
if "%PROJECT_ID%"=="" (
    echo [ERROR] No project ID set. Please run 'gcloud config set project YOUR_PROJECT_ID' first.
    exit /b 1
)

echo [INFO] Using project: %PROJECT_ID%

REM Set region
set REGION=us-central1
echo [INFO] Using region: %REGION%

REM Build and push image
echo [INFO] Building Market Price API image...
gcloud builds submit --config gcp/cloudbuild-market-price.yaml .

if %errorlevel% equ 0 (
    echo [INFO] ✅ Market Price API deployed successfully!
    
    REM Get service URL
    for /f "tokens=*" %%i in ('gcloud run services describe market-price-api --region=%REGION% --format="value(status.url)"') do set SERVICE_URL=%%i
    echo [INFO] 🌐 Service URL: %SERVICE_URL%
    echo [INFO] 📊 Health Check: %SERVICE_URL%/health
    echo [INFO] 💰 Market Prices: %SERVICE_URL%/price/current?crop=Rice
    echo [INFO] 🏪 Mandis: %SERVICE_URL%/mandis
    
    REM Test the service
    echo [INFO] Testing service health...
    curl -f "%SERVICE_URL%/health" >nul 2>&1
    if %errorlevel% equ 0 (
        echo [INFO] ✅ Service is healthy and responding!
    ) else (
        echo [WARNING] ⚠️ Service deployed but health check failed. Check logs with:
        echo [WARNING] gcloud run logs read market-price-api --region=%REGION%
    )
    
    echo [INFO] 🎉 Market Price API deployment completed!
    echo [INFO] 📝 To view logs: gcloud run logs read market-price-api --region=%REGION%
    echo [INFO] 🛑 To delete service: gcloud run services delete market-price-api --region=%REGION%
    
) else (
    echo [ERROR] ❌ Deployment failed!
    exit /b 1
)
