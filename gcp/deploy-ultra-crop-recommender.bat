@echo off
REM Ultra Crop Recommender - Google Cloud Run Deployment Script (Windows)
REM Specialized deployment script for the Ultra Crop Recommender API

setlocal enabledelayedexpansion

REM Configuration
set PROJECT_ID=
set REGION=us-central1
set SERVICE_NAME=ultra-crop-recommender-api
set IMAGE_NAME=ultra-crop-recommender
set SERVICE_ACCOUNT=ultra-crop-sa

REM Functions
:print_header
echo.
echo ================================================================
echo     ULTRA CROP RECOMMENDER - GOOGLE CLOUD RUN DEPLOYMENT
echo ================================================================
echo.
goto :eof

:print_success
echo ✅ %~1
goto :eof

:print_warning
echo ⚠️  %~1
goto :eof

:print_error
echo ❌ %~1
goto :eof

:print_info
echo ℹ️  %~1
goto :eof

:check_prerequisites
call :print_info "Checking prerequisites..."

REM Check gcloud CLI
gcloud version >nul 2>&1
if errorlevel 1 (
    call :print_error "Google Cloud CLI is not installed. Please install it first:"
    echo https://cloud.google.com/sdk/docs/install
    exit /b 1
)
call :print_success "Google Cloud CLI is available"

REM Check if authenticated
gcloud auth list --filter=status:ACTIVE --format="value(account)" | findstr . >nul
if errorlevel 1 (
    call :print_error "Not authenticated with Google Cloud. Please run:"
    echo gcloud auth login
    exit /b 1
)
call :print_success "Authenticated with Google Cloud"

REM Check if project is set
if "%PROJECT_ID%"=="" (
    call :print_error "PROJECT_ID is not set. Please set it in the script or export it:"
    echo set PROJECT_ID=your-project-id
    exit /b 1
)
call :print_success "Project ID: %PROJECT_ID%"

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker is not running. Please start Docker first."
    exit /b 1
)
call :print_success "Docker is running"
goto :eof

:setup_project
call :print_info "Setting up Google Cloud project..."

REM Set project
gcloud config set project %PROJECT_ID%

REM Enable required APIs
call :print_info "Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com run.googleapis.com secretmanager.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com

call :print_success "APIs enabled"
goto :eof

:create_service_account
call :print_info "Creating service account..."

REM Create service account
gcloud iam service-accounts create %SERVICE_ACCOUNT% --display-name="Ultra Crop Recommender Service Account" --description="Service account for Ultra Crop Recommender application" --project=%PROJECT_ID% 2>nul

REM Grant necessary roles
gcloud projects add-iam-policy-binding %PROJECT_ID% --member="serviceAccount:%SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
gcloud projects add-iam-policy-binding %PROJECT_ID% --member="serviceAccount:%SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com" --role="roles/cloudsql.client"

call :print_success "Service account created and configured"
goto :eof

:setup_secrets
call :print_info "Setting up secrets in Secret Manager..."

REM Create secrets in Secret Manager
echo your_openweather_api_key_here | gcloud secrets create openweather-api-key --data-file=- 2>nul
echo your_google_earth_engine_key_here | gcloud secrets create google-earth-engine-key --data-file=- 2>nul
echo your_bhuvan_api_key_here | gcloud secrets create bhuvan-api-key --data-file=- 2>nul
echo ultra-crop-secret-key-%RANDOM% | gcloud secrets create secret-key --data-file=- 2>nul

call :print_success "Secrets created in Secret Manager"
call :print_warning "Please update the secret values with your actual API keys:"
echo   gcloud secrets versions add openweather-api-key --data-file=-
echo   gcloud secrets versions add google-earth-engine-key --data-file=-
echo   gcloud secrets versions add bhuvan-api-key --data-file=-
goto :eof

:build_and_push_image
call :print_info "Building and pushing Docker image for Ultra Crop Recommender..."

REM Configure Docker for GCR
gcloud auth configure-docker

REM Build image
call :print_info "Building Docker image..."
docker build -f backend/Dockerfile.cloudrun -t gcr.io/%PROJECT_ID%/%IMAGE_NAME%:latest ./backend

REM Push image
call :print_info "Pushing image to Google Container Registry..."
docker push gcr.io/%PROJECT_ID%/%IMAGE_NAME%:latest

call :print_success "Image built and pushed successfully"
goto :eof

:deploy_to_cloud_run
call :print_info "Deploying Ultra Crop Recommender to Cloud Run..."

REM Deploy the service
gcloud run deploy %SERVICE_NAME% --image gcr.io/%PROJECT_ID%/%IMAGE_NAME%:latest --region %REGION% --platform managed --allow-unauthenticated --port 5020 --memory 4Gi --cpu 4 --max-instances 20 --min-instances 1 --concurrency 50 --timeout 600 --service-account %SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com --set-env-vars "ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5020,DEBUG=false,MODEL_PATH=/app/models,CACHE_TTL=3600,ULTRA_REQUEST_TIMEOUT=10.0" --set-secrets "OPENWEATHER_API_KEY=openweather-api-key:latest,GOOGLE_EARTH_ENGINE_KEY=google-earth-engine-key:latest,BHUVAN_API_KEY=bhuvan-api-key:latest,SECRET_KEY=secret-key:latest"

REM Get service URL
for /f "tokens=*" %%i in ('gcloud run services describe %SERVICE_NAME% --region=%REGION% --format="value(status.url)"') do set SERVICE_URL=%%i
call :print_success "Ultra Crop Recommender deployed successfully!"
echo Service URL: %SERVICE_URL%
goto :eof

:test_deployment
call :print_info "Testing Ultra Crop Recommender deployment..."

for /f "tokens=*" %%i in ('gcloud run services describe %SERVICE_NAME% --region=%REGION% --format="value(status.url)"') do set SERVICE_URL=%%i

REM Test health endpoint
call :print_info "Testing health endpoint..."
curl -f "%SERVICE_URL%/health" >nul 2>&1
if errorlevel 1 (
    call :print_warning "Health check failed - service may still be starting up"
) else (
    call :print_success "Health check passed"
)

echo.
call :print_success "Deployment testing completed!"
echo Service URL: %SERVICE_URL%
echo Health Check: %SERVICE_URL%/health
echo API Documentation: %SERVICE_URL%/docs
goto :eof

:show_logs
call :print_info "Showing recent logs..."
gcloud run logs read %SERVICE_NAME% --region=%REGION% --limit=50
goto :eof

:cleanup
call :print_info "Cleaning up Ultra Crop Recommender resources..."

REM Delete Cloud Run service
gcloud run services delete %SERVICE_NAME% --region=%REGION% --quiet 2>nul

REM Delete images
gcloud container images delete gcr.io/%PROJECT_ID%/%IMAGE_NAME%:latest --quiet 2>nul

call :print_success "Cleanup completed"
goto :eof

:show_help
echo Ultra Crop Recommender - Google Cloud Run Deployment Script
echo.
echo Usage: %0 [COMMAND] [OPTIONS]
echo.
echo Commands:
echo   setup                 Setup GCP project and enable APIs
echo   deploy                Deploy Ultra Crop Recommender to Cloud Run
echo   test                  Test deployment
echo   logs                  Show service logs
echo   cleanup               Clean up resources
echo   help                  Show this help message
echo.
echo Environment Variables:
echo   PROJECT_ID            Google Cloud Project ID (required)
echo   REGION                Deployment region (default: us-central1)
echo   SERVICE_NAME          Cloud Run service name (default: ultra-crop-recommender-api)
echo.
echo Examples:
echo   set PROJECT_ID=my-project ^&^& %0 setup
echo   set PROJECT_ID=my-project ^&^& %0 deploy
echo   set PROJECT_ID=my-project ^&^& %0 test
echo   set PROJECT_ID=my-project ^&^& %0 logs
echo   set PROJECT_ID=my-project ^&^& %0 cleanup
goto :eof

REM Main script
:main
call :print_header

REM Set PROJECT_ID from environment or argument
if not "%1"=="" if not "%1"=="setup" if not "%1"=="deploy" if not "%1"=="test" if not "%1"=="logs" if not "%1"=="cleanup" if not "%1"=="help" (
    set PROJECT_ID=%1
)

if "%PROJECT_ID%"=="" (
    call :print_error "PROJECT_ID is required. Set it as environment variable or first argument."
    echo Example: set PROJECT_ID=my-project ^&^& %0 setup
    exit /b 1
)

if "%2"=="setup" goto :setup
if "%2"=="deploy" goto :deploy
if "%2"=="test" goto :test
if "%2"=="logs" goto :logs
if "%2"=="cleanup" goto :cleanup
if "%2"=="help" goto :show_help
if "%2"=="-h" goto :show_help
if "%2"=="--help" goto :show_help
if "%2"=="" goto :setup

call :print_error "Unknown command: %2"
call :show_help
exit /b 1

:setup
call :check_prerequisites
call :setup_project
call :create_service_account
call :setup_secrets
call :print_success "GCP setup completed!"
goto :end

:deploy
call :check_prerequisites
call :build_and_push_image
call :deploy_to_cloud_run
call :test_deployment
goto :end

:test
call :test_deployment
goto :end

:logs
call :show_logs
goto :end

:cleanup
call :cleanup
goto :end

:show_help
call :show_help
goto :end

:end
endlocal
