#!/usr/bin/env python3
"""
SIH 2025 AI-Based Crop Recommendation System Startup Script
Starts all required APIs and services for the complete system
"""

import subprocess
import time
import sys
import os
import signal
import threading
from datetime import datetime

# API configurations
APIS = [
    {
        'name': 'Crop Recommendation API',
        'file': 'crop_api_production.py',
        'port': 8080,
        'description': 'Main crop recommendation ML models'
    },
    {
        'name': 'Weather Integration API',
        'file': 'weather_integration_api.py',
        'port': 5005,
        'description': 'Real-time weather data and forecasts'
    },
    {
        'name': 'Market Price API',
        'file': 'market_price_api.py',
        'port': 5004,
        'description': 'Market prices and profit calculations'
    },
    {
        'name': 'Yield Prediction API',
        'file': 'yield_prediction_api.py',
        'port': 5003,
        'description': 'ML-based yield forecasting'
    },
    {
        'name': 'Field Management API',
        'file': 'field_management_api.py',
        'port': 5002,
        'description': 'Field tracking and crop scheduling'
    },
    {
        'name': 'Satellite Soil API',
        'file': 'satellite_soil_api.py',
        'port': 5006,
        'description': 'Satellite data integration for soil properties'
    },
    {
        'name': 'Multilingual AI API',
        'file': 'multilingual_ai_api.py',
        'port': 5007,
        'description': 'Multilingual voice and chat support'
    },
    {
        'name': 'Disease Detection API',
        'file': 'ai_disease_detection_api.py',
        'port': 5008,
        'description': 'AI-powered plant disease detection'
    },
    {
        'name': 'Sustainability Scoring API',
        'file': 'sustainability_scoring_api.py',
        'port': 5009,
        'description': 'Sustainability and environmental impact analysis'
    },
    {
        'name': 'Crop Rotation API',
        'file': 'crop_rotation_api.py',
        'port': 5010,
        'description': 'Intelligent crop rotation planning'
    },
    {
        'name': 'Offline Capability API',
        'file': 'offline_capability_api.py',
        'port': 5011,
        'description': 'Offline functionality for low-connectivity regions'
    },
    {
        'name': 'Integrated SIH 2025 API',
        'file': 'sih_2025_integrated_api.py',
        'port': 5012,
        'description': 'Main integrated API combining all features'
    }
]

# Global process tracking
processes = []
running_apis = []

def start_api(api_config):
    """Start a single API"""
    try:
        print(f"🚀 Starting {api_config['name']} on port {api_config['port']}...")
        
        # Start the API process
        process = subprocess.Popen([
            sys.executable, api_config['file']
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        processes.append({
            'name': api_config['name'],
            'process': process,
            'port': api_config['port'],
            'file': api_config['file']
        })
        
        running_apis.append(api_config['name'])
        print(f"✅ {api_config['name']} started successfully")
        return True
        
    except Exception as e:
        print(f"❌ Failed to start {api_config['name']}: {str(e)}")
        return False

def check_api_health(port):
    """Check if an API is responding"""
    try:
        import requests
        response = requests.get(f"http://localhost:{port}/health", timeout=5)
        return response.status_code == 200
    except:
        return False

def wait_for_api(api_name, port, max_wait=30):
    """Wait for an API to become healthy"""
    print(f"⏳ Waiting for {api_name} to be ready...")
    
    for i in range(max_wait):
        if check_api_health(port):
            print(f"✅ {api_name} is healthy and ready")
            return True
        time.sleep(1)
    
    print(f"⚠️ {api_name} may not be ready after {max_wait} seconds")
    return False

def start_all_apis():
    """Start all APIs in sequence"""
    print("🌾 SIH 2025 AI-Based Crop Recommendation System")
    print("=" * 60)
    print(f"🕐 Starting at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Start APIs in dependency order
    api_order = [
        'Crop Recommendation API',  # Core ML models
        'Weather Integration API',  # Weather data
        'Market Price API',        # Market data
        'Yield Prediction API',    # Yield forecasting
        'Field Management API',    # Field tracking
        'Satellite Soil API',      # Soil data
        'Multilingual AI API',     # Language support
        'Disease Detection API',   # Disease detection
        'Sustainability Scoring API', # Sustainability
        'Crop Rotation API',       # Rotation planning
        'Offline Capability API',  # Offline support
        'Integrated SIH 2025 API'  # Main integrated API
    ]
    
    # Filter APIs by order
    ordered_apis = []
    for api_name in api_order:
        for api in APIS:
            if api['name'] == api_name:
                ordered_apis.append(api)
                break
    
    # Add any remaining APIs
    for api in APIS:
        if api not in ordered_apis:
            ordered_apis.append(api)
    
    # Start each API
    for api in ordered_apis:
        if start_api(api):
            # Wait for API to be ready (except for the last one)
            if api != ordered_apis[-1]:
                wait_for_api(api['name'], api['port'])
            time.sleep(2)  # Brief pause between APIs
        else:
            print(f"⚠️ Continuing without {api['name']}")
    
    print()
    print("🎉 All APIs started successfully!")
    print("=" * 60)
    print("📱 Available APIs:")
    for api in running_apis:
        print(f"  • {api}")
    print()
    print("🔗 Main Integrated API: http://localhost:5012")
    print("📊 Health Check: http://localhost:5012/health")
    print()
    print("📱 Flutter App Integration:")
    print("  • Update API base URL to: http://10.0.2.2:5012")
    print("  • For Android emulator access")
    print()
    print("🛑 Press Ctrl+C to stop all services")

def stop_all_apis():
    """Stop all running APIs"""
    print("\n🛑 Stopping all APIs...")
    
    for proc_info in processes:
        try:
            proc_info['process'].terminate()
            proc_info['process'].wait(timeout=5)
            print(f"✅ {proc_info['name']} stopped")
        except:
            try:
                proc_info['process'].kill()
                print(f"🔪 {proc_info['name']} force stopped")
            except:
                print(f"❌ Could not stop {proc_info['name']}")
    
    print("👋 All APIs stopped. Goodbye!")

def signal_handler(sig, frame):
    """Handle Ctrl+C signal"""
    print("\n🛑 Received interrupt signal...")
    stop_all_apis()
    sys.exit(0)

def monitor_apis():
    """Monitor running APIs"""
    while True:
        time.sleep(30)  # Check every 30 seconds
        
        for proc_info in processes:
            if proc_info['process'].poll() is not None:
                print(f"⚠️ {proc_info['name']} has stopped unexpectedly")
                # Optionally restart the API
                # start_api(proc_info)

def main():
    """Main function"""
    # Set up signal handler
    signal.signal(signal.SIGINT, signal_handler)
    
    # Check if we're in the right directory
    if not os.path.exists('sih_2025_integrated_api.py'):
        print("❌ Error: Please run this script from the Crop-Recommendation-App directory")
        sys.exit(1)
    
    # Start all APIs
    start_all_apis()
    
    # Start monitoring thread
    monitor_thread = threading.Thread(target=monitor_apis, daemon=True)
    monitor_thread.start()
    
    # Keep main thread alive
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        signal_handler(signal.SIGINT, None)

if __name__ == '__main__':
    main()
