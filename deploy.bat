@echo off
REM Ultra Crop Recommender - Windows Deployment Script
REM Supports multiple deployment scenarios

setlocal enabledelayedexpansion

REM Configuration
set PROJECT_NAME=ultra-crop-recommender
set VERSION=1.0.0
set DOCKER_REGISTRY=your-registry.com
set ENVIRONMENT=production

REM Colors (Windows doesn't support colors in batch, but we can use echo)
set SUCCESS=✅
set WARNING=⚠️
set ERROR=❌
set INFO=ℹ️

:print_header
echo.
echo ================================================================
echo            ULTRA CROP RECOMMENDER - DEPLOYMENT SCRIPT
echo                     Version: %VERSION%
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

:check_dependencies
call :print_info "Checking dependencies..."

REM Check Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "Docker is not installed. Please install Docker Desktop first."
    exit /b 1
)
call :print_success "Docker is available"

REM Check Docker Compose
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit /b 1
)
call :print_success "Docker Compose is available"

REM Check if Docker daemon is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "Docker daemon is not running. Please start Docker Desktop."
    exit /b 1
)
call :print_success "Docker daemon is running"
goto :eof

:create_environment_file
call :print_info "Creating environment configuration..."

if not exist .env (
    (
        echo # Ultra Crop Recommender Environment Configuration
        echo # Generated on %date% %time%
        echo.
        echo # API Configuration
        echo API_HOST=0.0.0.0
        echo API_PORT=5020
        echo DEBUG=false
        echo MODEL_PATH=./models
        echo CACHE_TTL=3600
        echo.
        echo # External APIs
        echo OPENWEATHER_API_KEY=your_openweather_api_key_here
        echo SOIL_GRIDS_API_KEY=your_soil_grids_api_key_here
        echo.
        echo # Database Configuration
        echo POSTGRES_PASSWORD=ultra_crop_secure_password_2024
        echo DATABASE_URL=postgresql://ultra_crop_user:ultra_crop_secure_password_2024@postgres:5432/ultra_crop
        echo.
        echo # Security
        echo SECRET_KEY=ultra-crop-secret-key-2024
        echo.
        echo # Frontend Configuration
        echo ULTRA_CROP_API_BASE_URL=http://ultra-crop-api:5020
        echo.
        echo # Deployment
        echo ENVIRONMENT=production
        echo VERSION=%VERSION%
    ) > .env
    call :print_success "Environment file created: .env"
) else (
    call :print_warning "Environment file already exists: .env"
)
goto :eof

:build_images
call :print_info "Building Docker images..."

REM Build backend
call :print_info "Building backend API image..."
docker build -t %PROJECT_NAME%-api:%VERSION% ./backend
if %errorlevel% neq 0 (
    call :print_error "Failed to build backend image"
    exit /b 1
)
docker tag %PROJECT_NAME%-api:%VERSION% %PROJECT_NAME%-api:latest
call :print_success "Backend API image built"

REM Build frontend
call :print_info "Building frontend image..."
docker build -t %PROJECT_NAME%-frontend:%VERSION% ./frontend
if %errorlevel% neq 0 (
    call :print_error "Failed to build frontend image"
    exit /b 1
)
docker tag %PROJECT_NAME%-frontend:%VERSION% %PROJECT_NAME%-frontend:latest
call :print_success "Frontend image built"
goto :eof

:deploy_local
call :print_info "Deploying locally with Docker Compose..."

REM Stop existing containers
docker-compose down --remove-orphans 2>nul

REM Start services
docker-compose up -d
if %errorlevel% neq 0 (
    call :print_error "Failed to start services with Docker Compose"
    exit /b 1
)

REM Wait for services to be ready
call :print_info "Waiting for services to start..."
timeout /t 30 /nobreak >nul

REM Check health
curl -f http://localhost:5020/health >nul 2>&1
if %errorlevel% equ 0 (
    call :print_success "Backend API is healthy"
) else (
    call :print_warning "Backend API health check failed"
)

curl -f http://localhost:80 >nul 2>&1
if %errorlevel% equ 0 (
    call :print_success "Frontend is accessible"
) else (
    call :print_warning "Frontend health check failed"
)

call :print_success "Local deployment completed!"
call :print_info "Backend API: http://localhost:5020"
call :print_info "Frontend: http://localhost:80"
goto :eof

:run_tests
call :print_info "Running deployment tests..."

REM Test backend API
curl -f http://localhost:5020/health >nul 2>&1
if %errorlevel% equ 0 (
    call :print_success "Backend API health check passed"
) else (
    call :print_error "Backend API health check failed"
    exit /b 1
)

REM Test frontend
curl -f http://localhost:80 >nul 2>&1
if %errorlevel% equ 0 (
    call :print_success "Frontend accessibility check passed"
) else (
    call :print_error "Frontend accessibility check failed"
    exit /b 1
)

REM Test API endpoints
call :print_info "Testing API endpoints..."

REM Test ultra-recommend endpoint
curl -s -X POST http://localhost:5020/ultra-recommend -H "Content-Type: application/json" -d "{\"latitude\": 28.6139, \"longitude\": 77.2090, \"farm_size\": 1.0, \"irrigation_type\": \"drip\", \"language\": \"en\"}" | findstr "success.*true" >nul
if %errorlevel% equ 0 (
    call :print_success "Ultra recommend endpoint test passed"
) else (
    call :print_error "Ultra recommend endpoint test failed"
    exit /b 1
)

call :print_success "All tests passed!"
goto :eof

:cleanup
call :print_info "Cleaning up..."

REM Stop containers
docker-compose down --remove-orphans 2>nul

REM Remove unused images
docker image prune -f

call :print_success "Cleanup completed"
goto :eof

:show_help
echo Ultra Crop Recommender - Windows Deployment Script
echo.
echo Usage: %0 [COMMAND]
echo.
echo Commands:
echo   local                 Deploy locally with Docker Compose
echo   build                 Build Docker images only
echo   test                  Run deployment tests
echo   cleanup               Clean up Docker resources
echo   help                  Show this help message
echo.
echo Examples:
echo   %0 local              Deploy locally
echo   %0 build              Build images only
echo   %0 test               Run tests
echo   %0 cleanup            Clean up
goto :eof

:main
call :print_header

if "%1"=="local" (
    call :check_dependencies
    call :create_environment_file
    call :build_images
    call :deploy_local
    call :run_tests
) else if "%1"=="build" (
    call :check_dependencies
    call :build_images
) else if "%1"=="test" (
    call :run_tests
) else if "%1"=="cleanup" (
    call :cleanup
) else if "%1"=="help" (
    call :show_help
) else if "%1"=="" (
    call :show_help
) else (
    call :print_error "Unknown command: %1"
    call :show_help
    exit /b 1
)

goto :eof

REM Run main function
call :main %*
