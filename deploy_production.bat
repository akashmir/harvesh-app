@echo off
REM Production Deployment Script for Market Price API (Windows)
echo 🚀 Starting Production Deployment...

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed. Please install Docker first.
    exit /b 1
)

REM Check if Docker Compose is installed
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker Compose is not installed. Please install Docker Compose first.
    exit /b 1
)

REM Create data directory
echo [INFO] Creating data directory...
if not exist "backend\data" mkdir backend\data

REM Build and start services
echo [INFO] Building and starting services...
docker-compose -f docker-compose.production.yml up --build -d

REM Wait for services to be ready
echo [INFO] Waiting for services to be ready...
timeout /t 10 /nobreak >nul

REM Check if services are running
echo [INFO] Checking service health...
curl -f http://localhost:5004/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] ✅ Market Price API is running successfully!
    echo [INFO] 🌐 API URL: http://localhost:5004
    echo [INFO] 📊 Health Check: http://localhost:5004/health
    echo [INFO] 📱 For Android emulator: http://10.0.2.2:5004
) else (
    echo [ERROR] ❌ Service health check failed!
    echo [INFO] Checking logs...
    docker-compose -f docker-compose.production.yml logs market-price-api
    exit /b 1
)

REM Show service status
echo [INFO] Service Status:
docker-compose -f docker-compose.production.yml ps

echo [INFO] 🎉 Production deployment completed successfully!
echo [INFO] 📝 To view logs: docker-compose -f docker-compose.production.yml logs -f
echo [INFO] 🛑 To stop services: docker-compose -f docker-compose.production.yml down
