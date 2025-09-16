#!/usr/bin/env python3
"""
SIH 2025 Harvest Enterprise - PostgreSQL System Startup
Starts all APIs with PostgreSQL database integration
"""

import os
import sys
import time
import subprocess
import signal
import threading
from datetime import datetime

# API Configuration with PostgreSQL
APIS = [
    {
        'name': 'Crop Recommendation API',
        'file': 'src/api/crop_api_production.py',
        'port': 8080,
        'description': 'ML-based crop recommendation system with PostgreSQL'
    },
    {
        'name': 'Weather Integration API',
        'file': 'src/api/weather_integration_api.py',
        'port': 5005,
        'description': 'Weather data integration with PostgreSQL'
    },
    {
        'name': 'Market Price API',
        'file': 'src/api/market_price_api.py',
        'port': 5004,
        'description': 'Market price prediction with PostgreSQL'
    },
    {
        'name': 'Yield Prediction API',
        'file': 'src/api/yield_prediction_api.py',
        'port': 5003,
        'description': 'Yield prediction with PostgreSQL'
    },
    {
        'name': 'Field Management API',
        'file': 'src/api/field_management_api.py',
        'port': 5002,
        'description': 'Field management with PostgreSQL'
    },
    {
        'name': 'Satellite Soil API',
        'file': 'src/api/satellite_soil_api.py',
        'port': 5006,
        'description': 'Satellite soil analysis with PostgreSQL'
    },
    {
        'name': 'Multilingual AI API',
        'file': 'src/api/multilingual_ai_api.py',
        'port': 5007,
        'description': 'Multilingual AI with PostgreSQL'
    },
    {
        'name': 'Disease Detection API',
        'file': 'src/api/ai_disease_detection_api.py',
        'port': 5008,
        'description': 'Disease detection with PostgreSQL'
    },
    {
        'name': 'Sustainability Scoring API',
        'file': 'src/api/sustainability_scoring_api.py',
        'port': 5009,
        'description': 'Sustainability scoring with PostgreSQL'
    },
    {
        'name': 'Crop Rotation API',
        'file': 'src/api/crop_rotation_api.py',
        'port': 5010,
        'description': 'Crop rotation with PostgreSQL'
    },
    {
        'name': 'Offline Capability API',
        'file': 'src/api/offline_capability_api.py',
        'port': 5011,
        'description': 'Offline capability with PostgreSQL'
    },
    {
        'name': 'SIH 2025 Integrated API',
        'file': 'src/api/sih_2025_integrated_api.py',
        'port': 5012,
        'description': 'Integrated API with PostgreSQL'
    }
]

# Global process list for cleanup
processes = []

def log(message, level="INFO"):
    """Log message with timestamp"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {level}: {message}")

def start_api(api):
    """Start a single API with PostgreSQL configuration"""
    try:
        log(f"🚀 Starting {api['name']} on port {api['port']}...")
        
        # Set environment variables for PostgreSQL
        env = os.environ.copy()
        env['PORT'] = str(api['port'])
        env['FLASK_ENV'] = 'production'
        env['DB_HOST'] = 'localhost'
        env['DB_PORT'] = '5432'
        env['DB_NAME'] = 'harvest_enterprise'
        env['DB_USER'] = 'postgres'
        env['DB_PASSWORD'] = 'K@shmir2442'
        
        # Start the API process
        process = subprocess.Popen(
            [sys.executable, api['file']],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        processes.append({
            'process': process,
            'api': api,
            'start_time': time.time()
        })
        
        log(f"✅ {api['name']} started (PID: {process.pid})")
        return True
        
    except Exception as e:
        log(f"❌ Failed to start {api['name']}: {e}", "ERROR")
        return False

def check_api_health(api, timeout=30):
    """Check if API is responding"""
    import requests
    
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            response = requests.get(f"http://localhost:{api['port']}/health", timeout=5)
            if response.status_code == 200:
                return True
        except:
            pass
        time.sleep(2)
    return False

def start_all_apis():
    """Start all APIs with PostgreSQL"""
    log("🌾 Starting SIH 2025 Harvest Enterprise - PostgreSQL System")
    log("=" * 60)
    
    # Start APIs one by one
    for api in APIS:
        if not start_api(api):
            log(f"⚠️ Skipping {api['name']} due to startup failure", "WARNING")
        time.sleep(3)  # Delay between starts
    
    log("⏳ Waiting for APIs to initialize...")
    time.sleep(15)
    
    # Check API health
    log("🔍 Checking API health...")
    healthy_apis = 0
    for api in APIS:
        if check_api_health(api):
            log(f"✅ {api['name']} is healthy")
            healthy_apis += 1
        else:
            log(f"⚠️ {api['name']} may not be ready", "WARNING")
    
    log(f"📊 {healthy_apis}/{len(APIS)} APIs are healthy")
    
    if healthy_apis > 0:
        log("🎉 PostgreSQL system startup completed!")
        log("🌐 Integrated API available at: http://localhost:5012")
        log("📱 Frontend can now connect to the backend")
    else:
        log("❌ No APIs are responding. Check logs for errors.", "ERROR")

def cleanup():
    """Clean up all processes"""
    log("🧹 Cleaning up processes...")
    for proc_info in processes:
        try:
            proc_info['process'].terminate()
            proc_info['process'].wait(timeout=5)
        except:
            try:
                proc_info['process'].kill()
            except:
                pass
    log("✅ Cleanup completed")

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    log("🛑 Shutdown signal received...")
    cleanup()
    sys.exit(0)

def main():
    """Main function"""
    print("🌾 SIH 2025 Harvest Enterprise - PostgreSQL System")
    print("=" * 60)
    
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Check if we're in the right directory
    if not os.path.exists('src/api/integrated_api.py'):
        log("❌ Please run this script from the backend directory", "ERROR")
        log("💡 Use: cd backend && python start_postgresql_system.py")
        return False
    
    # Start all APIs
    start_all_apis()
    
    # Keep the script running
    try:
        log("🔄 System is running. Press Ctrl+C to stop.")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        log("🛑 Shutdown requested by user")
    finally:
        cleanup()
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
