@echo off
echo 🌾 SIH 2025 Harvest Enterprise - System Startup
echo ============================================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if we're in the backend directory
if not exist "src\api" (
    echo ❌ Please run this script from the backend directory
    pause
    exit /b 1
)

echo ✅ Python found
echo ✅ Backend directory confirmed
echo.

REM Start the complete system
echo 🚀 Starting complete system...
python scripts\start_complete_system.py

pause
