# SIH 2025 Harvest Enterprise - System Startup Script
# PowerShell version for better Windows integration

Write-Host "🌾 SIH 2025 Harvest Enterprise - System Startup" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

# Check if Python is available
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python is not installed or not in PATH" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if we're in the backend directory
if (-not (Test-Path "src\api")) {
    Write-Host "❌ Please run this script from the backend directory" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Backend directory confirmed" -ForegroundColor Green
Write-Host ""

# Check if PostgreSQL is installed
$postgresqlPath = "C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe"
if (Test-Path $postgresqlPath) {
    Write-Host "✅ PostgreSQL found" -ForegroundColor Green
} else {
    Write-Host "⚠️  PostgreSQL not found at expected location" -ForegroundColor Yellow
    Write-Host "   Please ensure PostgreSQL is installed" -ForegroundColor Yellow
}

Write-Host ""

# Start the complete system
Write-Host "🚀 Starting complete system..." -ForegroundColor Cyan
Write-Host "   This will start PostgreSQL and all working APIs" -ForegroundColor Gray
Write-Host "   Press Ctrl+C to stop the system" -ForegroundColor Gray
Write-Host ""

try {
    python scripts\start_complete_system.py
} catch {
    Write-Host "❌ Error starting system: $_" -ForegroundColor Red
} finally {
    Write-Host ""
    Write-Host "🛑 System stopped" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
}
