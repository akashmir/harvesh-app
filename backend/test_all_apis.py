#!/usr/bin/env python3
"""
Comprehensive API Testing Script for SIH 2025 Harvest Enterprise
Tests all APIs individually and reports results
"""

import sys
import os
import subprocess
import time
import requests
import json
from datetime import datetime

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# API Configuration
APIS = [
    {
        'name': 'Crop Recommendation API',
        'file': 'src/api/crop_api_production.py',
        'port': 8080,
        'test_endpoint': '/health',
        'expected_status': 200
    },
    {
        'name': 'Weather Integration API',
        'file': 'src/api/weather_integration_api.py',
        'port': 5005,
        'test_endpoint': '/health',
        'expected_status': 200
    },
    {
        'name': 'Market Price API',
        'file': 'src/api/market_price_api.py',
        'port': 5004,
        'test_endpoint': '/health',
        'expected_status': 200
    },
    {
        'name': 'Yield Prediction API',
        'file': 'src/api/yield_prediction_api.py',
        'port': 5003,
        'test_endpoint': '/health',
        'expected_status': 200
    },
    {
        'name': 'Field Management API',
        'file': 'src/api/field_management_api.py',
        'port': 5002,
        'test_endpoint': '/health',
        'expected_status': 200
    },
    {
        'name': 'Satellite Soil API',
        'file': 'src/api/satellite_soil_api.py',
        'port': 5006,
        'test_endpoint': '/health',
        'expected_status': 200
    },
    {
        'name': 'Multilingual AI API',
        'file': 'src/api/multilingual_ai_api.py',
        'port': 5007,
        'test_endpoint': '/health',
        'expected_status': 200
    },
    {
        'name': 'Disease Detection API',
        'file': 'src/api/ai_disease_detection_api.py',
        'port': 5008,
        'test_endpoint': '/health',
        'expected_status': 200
    },
    {
        'name': 'Sustainability Scoring API',
        'file': 'src/api/sustainability_scoring_api.py',
        'port': 5009,
        'test_endpoint': '/health',
        'expected_status': 200
    },
    {
        'name': 'Crop Rotation API',
        'file': 'src/api/crop_rotation_api.py',
        'port': 5010,
        'test_endpoint': '/health',
        'expected_status': 200
    },
    {
        'name': 'Offline Capability API',
        'file': 'src/api/offline_capability_api.py',
        'port': 5011,
        'test_endpoint': '/health',
        'expected_status': 200
    },
    {
        'name': 'SIH 2025 Integrated API',
        'file': 'src/api/sih_2025_integrated_api.py',
        'port': 5012,
        'test_endpoint': '/health',
        'expected_status': 200
    }
]

def log(message, level="INFO"):
    """Log message with timestamp"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {level}: {message}")

def test_api_import(api):
    """Test if API can be imported without errors"""
    try:
        log(f"📦 Testing imports for {api['name']}...")
        
        # Extract module name from file path
        module_path = api['file'].replace('/', '.').replace('.py', '')
        
        # Try to import the module
        __import__(module_path)
        log(f"✅ {api['name']} - Imports successful")
        return True, "Imports successful"
        
    except Exception as e:
        log(f"❌ {api['name']} - Import failed: {e}", "ERROR")
        return False, str(e)

def start_api_process(api):
    """Start API as a subprocess"""
    try:
        log(f"🚀 Starting {api['name']} on port {api['port']}...")
        
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
        
        return process, None
        
    except Exception as e:
        log(f"❌ Failed to start {api['name']}: {e}", "ERROR")
        return None, str(e)

def test_api_health(api, timeout=30):
    """Test if API responds to health check"""
    try:
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                response = requests.get(f"http://localhost:{api['port']}{api['test_endpoint']}", timeout=5)
                if response.status_code == api['expected_status']:
                    log(f"✅ {api['name']} - Health check passed")
                    return True, f"Status: {response.status_code}, Response: {response.text[:100]}"
            except requests.exceptions.RequestException:
                pass
            time.sleep(2)
        
        log(f"⚠️ {api['name']} - Health check timeout", "WARNING")
        return False, "Health check timeout"
        
    except Exception as e:
        log(f"❌ {api['name']} - Health check failed: {e}", "ERROR")
        return False, str(e)

def test_single_api(api):
    """Test a single API comprehensively"""
    log(f"\n{'='*60}")
    log(f"🧪 Testing {api['name']}")
    log(f"{'='*60}")
    
    results = {
        'name': api['name'],
        'file': api['file'],
        'port': api['port'],
        'import_test': False,
        'import_error': None,
        'startup_test': False,
        'startup_error': None,
        'health_test': False,
        'health_error': None,
        'process': None
    }
    
    # Test 1: Import test
    import_success, import_error = test_api_import(api)
    results['import_test'] = import_success
    results['import_error'] = import_error
    
    if not import_success:
        log(f"❌ {api['name']} - Skipping further tests due to import failure")
        return results
    
    # Test 2: Startup test
    process, startup_error = start_api_process(api)
    results['process'] = process
    results['startup_error'] = startup_error
    
    if process is None:
        log(f"❌ {api['name']} - Skipping health test due to startup failure")
        return results
    
    results['startup_test'] = True
    
    # Wait for API to start
    log(f"⏳ Waiting for {api['name']} to initialize...")
    time.sleep(10)
    
    # Test 3: Health test
    health_success, health_error = test_api_health(api)
    results['health_test'] = health_success
    results['health_error'] = health_error
    
    # Cleanup
    if process:
        try:
            process.terminate()
            process.wait(timeout=5)
            log(f"🧹 {api['name']} - Process terminated")
        except:
            try:
                process.kill()
            except:
                pass
    
    return results

def main():
    """Main testing function"""
    print("🌾 SIH 2025 Harvest Enterprise - Comprehensive API Testing")
    print("=" * 70)
    
    all_results = []
    
    # Test each API individually
    for api in APIS:
        result = test_single_api(api)
        all_results.append(result)
        time.sleep(2)  # Small delay between tests
    
    # Generate summary report
    print("\n" + "="*70)
    print("📊 TESTING SUMMARY REPORT")
    print("="*70)
    
    working_apis = 0
    import_issues = 0
    startup_issues = 0
    health_issues = 0
    
    for result in all_results:
        status = "❌ FAILED"
        if result['health_test']:
            status = "✅ WORKING"
            working_apis += 1
        elif result['startup_test']:
            status = "⚠️ STARTUP OK, HEALTH FAILED"
            health_issues += 1
        elif result['import_test']:
            status = "⚠️ IMPORT OK, STARTUP FAILED"
            startup_issues += 1
        else:
            status = "❌ IMPORT FAILED"
            import_issues += 1
        
        print(f"{status} | {result['name']}")
        if result['import_error']:
            print(f"    Import Error: {result['import_error']}")
        if result['startup_error']:
            print(f"    Startup Error: {result['startup_error']}")
        if result['health_error']:
            print(f"    Health Error: {result['health_error']}")
    
    print(f"\n📈 STATISTICS:")
    print(f"✅ Working APIs: {working_apis}/{len(APIS)}")
    print(f"❌ Import Issues: {import_issues}")
    print(f"⚠️ Startup Issues: {startup_issues}")
    print(f"⚠️ Health Issues: {health_issues}")
    
    if working_apis > 0:
        print(f"\n🎉 {working_apis} APIs are working! The system is partially functional.")
    else:
        print(f"\n❌ No APIs are working. All APIs need fixes.")
    
    return all_results

if __name__ == "__main__":
    results = main()
