@echo off
REM Ultra Crop Recommender - Google Cloud Platform Deployment Script for Windows
REM Supports Cloud Run, GKE, and App Engine deployments

setlocal enabledelayedexpansion

REM Configuration
set PROJECT_ID=
set REGION=us-central1
set ZONE=us-central1-a
set CLUSTER_NAME=ultra-crop-cluster
set SERVICE_ACCOUNT=ultra-crop-sa
set DEPLOYMENT_TYPE=cloudrun

REM Colors (Windows doesn't support colors in batch, but we can use echo)
set SUCCESS=✅
set WARNING=⚠️
set ERROR=❌
set INFO=ℹ️

:print_header
echo.
echo ================================================================
echo     ULTRA CROP RECOMMENDER - GOOGLE CLOUD DEPLOYMENT
echo ================================================================
echo.
goto :eof

:print_success
echo %SUCCESS% %~1
goto :eof

:print_warning
echo %WARNING% %~1
goto :eof

:print_error
echo %ERROR% %~1
goto :eof

:print_info
echo %INFO% %~1
goto :eof

:check_prerequisites
call :print_info "Checking prerequisites..."

REM Check gcloud CLI
gcloud --version >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "Google Cloud CLI is not installed. Please install it first:"
    echo https://cloud.google.com/sdk/docs/install
    exit /b 1
)
call :print_success "Google Cloud CLI is available"

REM Check if authenticated
gcloud auth list --filter=status:ACTIVE --format="value(account)" | findstr . >nul
if %errorlevel% neq 0 (
    call :print_error "Not authenticated with Google Cloud. Please run:"
    echo gcloud auth login
    exit /b 1
)
call :print_success "Authenticated with Google Cloud"

REM Check if project is set
if "%PROJECT_ID%"=="" (
    call :print_error "PROJECT_ID is not set. Please set it:"
    echo set PROJECT_ID=your-project-id
    exit /b 1
)
call :print_success "Project ID: %PROJECT_ID%"
goto :eof

:setup_project
call :print_info "Setting up Google Cloud project..."

REM Set project
gcloud config set project %PROJECT_ID%

REM Enable required APIs
call :print_info "Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com run.googleapis.com container.googleapis.com compute.googleapis.com secretmanager.googleapis.com cloudresourcemanager.googleapis.com

call :print_success "APIs enabled"
goto :eof

:create_service_account
call :print_info "Creating service account..."

REM Create service account
gcloud iam service-accounts create %SERVICE_ACCOUNT% --display-name="Ultra Crop Recommender Service Account" --description="Service account for Ultra Crop Recommender application" --project=%PROJECT_ID% 2>nul

REM Grant necessary roles
gcloud projects add-iam-policy-binding %PROJECT_ID% --member="serviceAccount:%SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com" --role="roles/cloudsql.client"
gcloud projects add-iam-policy-binding %PROJECT_ID% --member="serviceAccount:%SERVICE_ACCOUNT%@%PROJECT_ID%.iam.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"

call :print_success "Service account created and configured"
goto :eof

:setup_secrets
call :print_info "Setting up secrets..."

REM Create secrets in Secret Manager
echo your_openweather_api_key_here | gcloud secrets create openweather-api-key --data-file=- 2>nul
echo your_soil_grids_api_key_here | gcloud secrets create soil-grids-api-key --data-file=- 2>nul
echo your_google_maps_api_key_here | gcloud secrets create google-maps-api-key --data-file=- 2>nul
echo ultra-crop-secret-key-%RANDOM% | gcloud secrets create secret-key --data-file=- 2>nul

call :print_success "Secrets created in Secret Manager"
goto :eof

:build_and_push_images
call :print_info "Building and pushing Docker images..."

REM Configure Docker for GCR
gcloud auth configure-docker

REM Build and push backend
call :print_info "Building backend image..."
docker build -t gcr.io/%PROJECT_ID%/ultra-crop-api:latest ./backend
if %errorlevel% neq 0 (
    call :print_error "Failed to build backend image"
    exit /b 1
)
docker push gcr.io/%PROJECT_ID%/ultra-crop-api:latest

REM Build and push frontend
call :print_info "Building frontend image..."
docker build -t gcr.io/%PROJECT_ID%/ultra-crop-frontend:latest ./frontend
if %errorlevel% neq 0 (
    call :print_error "Failed to build frontend image"
    exit /b 1
)
docker push gcr.io/%PROJECT_ID%/ultra-crop-frontend:latest

call :print_success "Images built and pushed to GCR"
goto :eof

:deploy_cloud_run
call :print_info "Deploying to Cloud Run..."

REM Deploy backend
call :print_info "Deploying backend API..."
gcloud run deploy ultra-crop-api --image gcr.io/%PROJECT_ID%/ultra-crop-api:latest --region %REGION% --platform managed --allow-unauthenticated --port 5020 --memory 2Gi --cpu 2 --max-instances 10 --set-env-vars "ENVIRONMENT=production,API_HOST=0.0.0.0,API_PORT=5020" --set-secrets "OPENWEATHER_API_KEY=openweather-api-key:latest,SOIL_GRIDS_API_KEY=soil-grids-api-key:latest,SECRET_KEY=secret-key:latest"

REM Get backend URL
for /f "tokens=*" %%i in ('gcloud run services describe ultra-crop-api --region=%REGION% --format="value(status.url)"') do set BACKEND_URL=%%i
call :print_success "Backend deployed: %BACKEND_URL%"

REM Deploy frontend
call :print_info "Deploying frontend..."
gcloud run deploy ultra-crop-frontend --image gcr.io/%PROJECT_ID%/ultra-crop-frontend:latest --region %REGION% --platform managed --allow-unauthenticated --port 80 --memory 1Gi --cpu 1 --max-instances 5 --set-env-vars "ULTRA_CROP_API_BASE_URL=%BACKEND_URL%" --set-secrets "GOOGLE_MAPS_API_KEY=google-maps-api-key:latest"

REM Get frontend URL
for /f "tokens=*" %%i in ('gcloud run services describe ultra-crop-frontend --region=%REGION% --format="value(status.url)"') do set FRONTEND_URL=%%i
call :print_success "Frontend deployed: %FRONTEND_URL%"

echo.
call :print_success "Cloud Run deployment completed!"
echo Backend API: %BACKEND_URL%
echo Frontend: %FRONTEND_URL%
goto :eof

:test_deployment
call :print_info "Testing deployment..."

REM Test backend health
curl -f "%BACKEND_URL%/health" >nul 2>&1
if %errorlevel% equ 0 (
    call :print_success "Backend API health check passed"
) else (
    call :print_warning "Backend API health check failed"
)

REM Test frontend
curl -f "%FRONTEND_URL%" >nul 2>&1
if %errorlevel% equ 0 (
    call :print_success "Frontend accessibility check passed"
) else (
    call :print_warning "Frontend accessibility check failed"
)

echo.
call :print_success "Deployment URLs:"
echo Backend API: %BACKEND_URL%
echo Frontend: %FRONTEND_URL%
goto :eof

:cleanup
call :print_info "Cleaning up resources..."

gcloud run services delete ultra-crop-api --region=%REGION% --quiet 2>nul
gcloud run services delete ultra-crop-frontend --region=%REGION% --quiet 2>nul

call :print_success "Cleanup completed"
goto :eof

:show_help
echo Ultra Crop Recommender - Google Cloud Deployment Script for Windows
echo.
echo Usage: %0 [PROJECT_ID] [COMMAND]
echo.
echo Commands:
echo   setup                 Setup GCP project and enable APIs
echo   deploy                Deploy application to Cloud Run
echo   test                  Test deployment
echo   cleanup               Clean up resources
echo   help                  Show this help message
echo.
echo Examples:
echo   %0 my-project setup
echo   %0 my-project deploy
echo   %0 my-project test
echo   %0 my-project cleanup
goto :eof

:main
call :print_header

if "%1"=="" (
    call :print_error "PROJECT_ID is required as first argument"
    call :show_help
    exit /b 1
)

set PROJECT_ID=%1

if "%2"=="setup" (
    call :check_prerequisites
    call :setup_project
    call :create_service_account
    call :setup_secrets
    call :print_success "GCP setup completed!"
) else if "%2"=="deploy" (
    call :check_prerequisites
    call :build_and_push_images
    call :deploy_cloud_run
    call :test_deployment
) else if "%2"=="test" (
    call :test_deployment
) else if "%2"=="cleanup" (
    call :cleanup
) else if "%2"=="help" (
    call :show_help
) else (
    call :print_error "Unknown command: %2"
    call :show_help
    exit /b 1
)

goto :eof

REM Run main function
call :main %*
