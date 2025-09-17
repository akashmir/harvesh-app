@echo off
echo ================================================================
echo.
echo             ULTRA CROP RECOMMENDER SYSTEM
echo.
echo        Advanced AI-Driven Crop Recommendation Platform
echo                  (No PostgreSQL Required)
echo.
echo ================================================================
echo.

REM Check if we're in the backend directory
if not exist "ultra_crop_recommender_standalone.py" (
    echo Error: Please run this script from the backend directory
    echo Current directory: %CD%
    pause
    exit /b 1
)

REM Try to activate virtual environment if it exists
if exist "..\.venv\Scripts\activate.bat" (
    echo Activating virtual environment...
    call "..\.venv\Scripts\activate.bat"
) else (
    echo No virtual environment found, using system Python
)

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.8+ and try again
    pause
    exit /b 1
)

echo.
echo Starting Ultra Crop Recommender System...
echo This version uses SQLite databases (no PostgreSQL required)
echo.

REM Start the complete system
python start_ultra_complete.py

echo.
echo System has been stopped.
pause
