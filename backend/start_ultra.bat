@echo off
echo ================================================================
echo.
echo             ULTRA CROP RECOMMENDER SYSTEM
echo.
echo        Advanced AI-Driven Crop Recommendation Platform
echo.
echo ================================================================
echo.

REM Activate virtual environment if it exists
if exist "..\..\.venv\Scripts\activate.bat" (
    echo Activating virtual environment...
    call "..\..\.venv\Scripts\activate.bat"
)

REM Start the Ultra Crop Recommender
echo Starting Ultra Crop Recommender...
python ultra_crop_recommender_standalone.py

pause
