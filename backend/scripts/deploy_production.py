"""
Production Deployment Script
Deploys the consolidated production API with monitoring
"""

import subprocess
import sys
import os
import time
import requests
import json
from datetime import datetime

def run_command(command, shell=True):
    """Run a command and return the result"""
    try:
        result = subprocess.run(command, shell=shell, capture_output=True, text=True)
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def check_dependencies():
    """Check if all required dependencies are installed"""
    print("🔍 Checking dependencies...")
    
    required_packages = [
        'flask', 'flask-cors', 'joblib', 'numpy', 'pandas', 
        'scikit-learn', 'tensorflow', 'psutil', 'requests'
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        print(f"❌ Missing packages: {', '.join(missing_packages)}")
        print("Installing missing packages...")
        success, stdout, stderr = run_command(f"pip install {' '.join(missing_packages)}")
        if not success:
            print(f"❌ Failed to install packages: {stderr}")
            return False
    
    print("✅ All dependencies available")
    return True

def check_models():
    """Check if model files exist"""
    print("🔍 Checking model files...")
    
    required_files = [
        'models/random_forest_model.pkl',
        'models/scaler.pkl',
        'models/label_encoder.pkl',
        'models/model_info.json'
    ]
    
    missing_files = []
    for file_path in required_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
    
    if missing_files:
        print(f"❌ Missing model files: {', '.join(missing_files)}")
        return False
    
    print("✅ All model files available")
    return True

def start_production_api():
    """Start the production API"""
    print("🚀 Starting production API...")
    
    # Kill any existing processes on port 8080
    run_command("netstat -ano | findstr :8080")
    run_command("taskkill /F /IM python.exe")
    
    # Start the production API
    success, stdout, stderr = run_command("python production_crop_api.py", shell=False)
    if not success:
        print(f"❌ Failed to start production API: {stderr}")
        return False
    
    print("✅ Production API started")
    return True

def start_monitoring_dashboard():
    """Start the monitoring dashboard"""
    print("📊 Starting monitoring dashboard...")
    
    # Start monitoring dashboard in background
    success, stdout, stderr = run_command("start python monitoring_dashboard.py", shell=True)
    if not success:
        print(f"❌ Failed to start monitoring dashboard: {stderr}")
        return False
    
    print("✅ Monitoring dashboard started")
    return True

def test_api_endpoints():
    """Test API endpoints"""
    print("🧪 Testing API endpoints...")
    
    base_url = "http://localhost:8080"
    endpoints = [
        ("/health", "GET"),
        ("/status", "GET"),
        ("/crops", "GET"),
        ("/features", "GET"),
        ("/metrics", "GET")
    ]
    
    for endpoint, method in endpoints:
        try:
            if method == "GET":
                response = requests.get(f"{base_url}{endpoint}", timeout=10)
            else:
                response = requests.post(f"{base_url}{endpoint}", timeout=10)
            
            if response.status_code == 200:
                print(f"✅ {endpoint} - OK")
            else:
                print(f"❌ {endpoint} - Status: {response.status_code}")
        except Exception as e:
            print(f"❌ {endpoint} - Error: {str(e)}")
    
    # Test crop recommendation
    try:
        test_data = {
            "N": 90, "P": 42, "K": 43,
            "temperature": 20.88, "humidity": 82,
            "ph": 6.5, "rainfall": 202.94,
            "model_type": "rf"
        }
        response = requests.post(f"{base_url}/recommend", json=test_data, timeout=10)
        if response.status_code == 200:
            result = response.json()
            print(f"✅ /recommend - OK (Recommended: {result.get('recommended_crop', 'Unknown')})")
        else:
            print(f"❌ /recommend - Status: {response.status_code}")
    except Exception as e:
        print(f"❌ /recommend - Error: {str(e)}")

def create_production_config():
    """Create production configuration files"""
    print("📝 Creating production configuration...")
    
    # Create production environment file
    env_content = """# Production Environment Configuration
SECRET_KEY=agrismart-production-key-2024
FLASK_ENV=production
FLASK_DEBUG=False

# Rate Limiting
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_WINDOW=3600

# Performance Monitoring
PERFORMANCE_MONITORING=true
METRICS_RETENTION_HOURS=24

# CORS Configuration
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# API Configuration
PORT=8080
"""
    
    with open('.env.production', 'w') as f:
        f.write(env_content)
    
    print("✅ Production configuration created")

def create_startup_script():
    """Create startup script for production"""
    print("📝 Creating startup script...")
    
    startup_content = """@echo off
echo Starting Crop Recommendation API Production Environment...

echo Starting Production API...
start "Production API" python production_crop_api.py

timeout /t 5 /nobreak >nul

echo Starting Monitoring Dashboard...
start "Monitoring Dashboard" python monitoring_dashboard.py

echo Production environment started!
echo API: http://localhost:8080
echo Dashboard: http://localhost:5001
echo.
echo Press any key to stop all services...
pause >nul

echo Stopping services...
taskkill /F /IM python.exe
echo Services stopped.
"""
    
    with open('start_production.bat', 'w') as f:
        f.write(startup_content)
    
    print("✅ Startup script created")

def main():
    """Main deployment function"""
    print("🚀 Crop Recommendation API - Production Deployment")
    print("=" * 60)
    
    # Check dependencies
    if not check_dependencies():
        print("❌ Dependency check failed")
        return False
    
    # Check models
    if not check_models():
        print("❌ Model check failed")
        return False
    
    # Create configuration
    create_production_config()
    create_startup_script()
    
    # Start services
    print("\n🚀 Starting production services...")
    
    # Start production API in background
    import threading
    def start_api():
        os.system("python production_crop_api.py")
    
    api_thread = threading.Thread(target=start_api, daemon=True)
    api_thread.start()
    
    # Wait for API to start
    print("⏳ Waiting for API to start...")
    time.sleep(10)
    
    # Test API
    test_api_endpoints()
    
    # Start monitoring dashboard
    start_monitoring_dashboard()
    
    print("\n🎉 Production deployment complete!")
    print("=" * 60)
    print("📊 Services running:")
    print("  • Production API: http://localhost:8080")
    print("  • Monitoring Dashboard: http://localhost:5001")
    print("  • Health Check: http://localhost:8080/health")
    print("  • Metrics: http://localhost:8080/metrics")
    print("\n📝 Configuration files created:")
    print("  • .env.production - Environment configuration")
    print("  • start_production.bat - Startup script")
    print("\n🔧 To stop services: taskkill /F /IM python.exe")
    print("🔧 To restart: Run start_production.bat")
    
    return True

if __name__ == "__main__":
    success = main()
    if not success:
        sys.exit(1)
    
    print("\n✅ Deployment successful! Press Ctrl+C to exit.")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n🛑 Shutting down...")
        os.system("taskkill /F /IM python.exe")
        print("✅ Shutdown complete.")
