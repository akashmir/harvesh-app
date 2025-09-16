#!/usr/bin/env python3
"""
SIH 2025 Harvest Enterprise - Minimal Working System
Starts only the essential APIs without database dependencies
"""

import os
import sys
import time
import subprocess
import signal
import threading
from datetime import datetime

# Essential APIs only
ESSENTIAL_APIS = [
    {
        'name': 'Crop Recommendation API',
        'file': 'crop_api_production.py',
        'port': 8080,
        'description': 'ML-based crop recommendation system'
    },
    {
        'name': 'Weather Integration API',
        'file': 'weather_integration_api.py',
        'port': 5005,
        'description': 'Weather data integration and forecasting'
    },
    {
        'name': 'Market Price API',
        'file': 'market_price_api.py',
        'port': 5004,
        'description': 'Market price prediction and analysis'
    },
    {
        'name': 'SIH 2025 Integrated API',
        'file': 'sih_2025_integrated_api.py',
        'port': 5012,
        'description': 'Main integrated API orchestrator'
    }
]

# Global process list for cleanup
processes = []

def log(message, level="INFO"):
    """Log message with timestamp"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {level}: {message}")

def start_api(api):
    """Start a single API"""
    try:
        log(f"Starting {api['name']} on port {api['port']}...")
        
        # Set environment variables
        env = os.environ.copy()
        env['PORT'] = str(api['port'])
        env['FLASK_ENV'] = 'production'
        
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
        
        log(f"{api['name']} started (PID: {process.pid})")
        return True
        
    except Exception as e:
        log(f"Failed to start {api['name']}: {e}", "ERROR")
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

def start_essential_apis():
    """Start essential APIs only"""
    log("Starting SIH 2025 Harvest Enterprise - Essential APIs")
    log("=" * 60)
    
    # Start APIs one by one
    for api in ESSENTIAL_APIS:
        if not start_api(api):
            log(f"Skipping {api['name']} due to startup failure", "WARNING")
        time.sleep(3)  # Longer delay between starts
    
    log("Waiting for APIs to initialize...")
    time.sleep(15)
    
    # Check API health
    log("Checking API health...")
    healthy_apis = 0
    for api in ESSENTIAL_APIS:
        if check_api_health(api):
            log(f"{api['name']} is healthy")
            healthy_apis += 1
        else:
            log(f"{api['name']} may not be ready", "WARNING")
    
    log(f"{healthy_apis}/{len(ESSENTIAL_APIS)} APIs are healthy")
    
    if healthy_apis > 0:
        log("Essential system startup completed!")
        log("Integrated API available at: http://localhost:5012")
        log("Frontend can now connect to the backend")
        log("This is a minimal working version - some features may be limited")
    else:
        log("No APIs are responding. Check logs for errors.", "ERROR")

def cleanup():
    """Clean up all processes"""
    log("Cleaning up processes...")
    for proc_info in processes:
        try:
            proc_info['process'].terminate()
            proc_info['process'].wait(timeout=5)
        except:
            try:
                proc_info['process'].kill()
            except:
                pass
    log("Cleanup completed")

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    log("Shutdown signal received...")
    cleanup()
    sys.exit(0)

def main():
    """Main function"""
    print("SIH 2025 Harvest Enterprise - Minimal Working System")
    print("=" * 60)
    
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Check if we're in the right directory
    if not os.path.exists('sih_2025_integrated_api.py'):
        log("Please run this script from the backend directory", "ERROR")
        log("Use: cd backend && python scripts/start_system_minimal.py")
        return False
    
    # Start essential APIs
    start_essential_apis()
    
    # Keep the script running
    try:
        log("System is running. Press Ctrl+C to stop.")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        log("Shutdown requested by user")
    finally:
        cleanup()
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)