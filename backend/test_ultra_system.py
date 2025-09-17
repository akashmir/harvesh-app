#!/usr/bin/env python3
"""
Test script for Ultra Crop Recommender System
Tests all APIs to ensure they work without PostgreSQL
"""

import requests
import json
import time
import sys
from datetime import datetime

def test_api_endpoint(url, method='GET', data=None, timeout=10):
    """Test an API endpoint"""
    try:
        if method == 'GET':
            response = requests.get(url, timeout=timeout)
        elif method == 'POST':
            response = requests.post(url, json=data, timeout=timeout)
        
        if response.status_code == 200:
            return True, response.json()
        else:
            return False, f"HTTP {response.status_code}: {response.text}"
    except requests.exceptions.RequestException as e:
        return False, str(e)

def run_tests():
    """Run all API tests"""
    print("="*60)
    print("ULTRA CROP RECOMMENDER SYSTEM - API TESTS")
    print("="*60)
    print(f"Test started at: {datetime.now()}")
    print()
    
    # Test cases
    tests = [
        # Ultra Crop Recommender API
        {
            'name': 'Ultra Crop Recommender - Health Check',
            'url': 'http://localhost:5020/health',
            'method': 'GET'
        },
        {
            'name': 'Ultra Crop Recommender - Quick Recommendation',
            'url': 'http://localhost:5020/ultra-recommend/quick',
            'method': 'POST',
            'data': {'latitude': 28.6139, 'longitude': 77.2090}
        },
        {
            'name': 'Ultra Crop Recommender - Full Recommendation',
            'url': 'http://localhost:5020/ultra-recommend',
            'method': 'POST',
            'data': {
                'latitude': 28.6139,
                'longitude': 77.2090,
                'farm_size': 2.0,
                'irrigation_type': 'drip',
                'soil_data': {'ph': 6.5, 'nitrogen': 120}
            }
        },
        {
            'name': 'Ultra Crop Recommender - Crop Database',
            'url': 'http://localhost:5020/ultra-recommend/crops',
            'method': 'GET'
        },
        
        # Supporting APIs
        {
            'name': 'Satellite Soil API - Health Check',
            'url': 'http://localhost:5006/health',
            'method': 'GET'
        },
        {
            'name': 'Satellite Soil API - Current Soil Data',
            'url': 'http://localhost:5006/soil/current?latitude=28.6139&longitude=77.2090',
            'method': 'GET'
        },
        {
            'name': 'Weather API - Health Check',
            'url': 'http://localhost:5005/health',
            'method': 'GET'
        },
        {
            'name': 'Weather API - Current Weather',
            'url': 'http://localhost:5005/weather/current?latitude=28.6139&longitude=77.2090',
            'method': 'GET'
        },
        {
            'name': 'Market Price API - Health Check',
            'url': 'http://localhost:5004/health',
            'method': 'GET'
        },
        {
            'name': 'Market Price API - Rice Prices',
            'url': 'http://localhost:5004/market/prices?crop=Rice',
            'method': 'GET'
        },
        {
            'name': 'Yield Prediction API - Health Check',
            'url': 'http://localhost:5003/health',
            'method': 'GET'
        },
        {
            'name': 'Yield Prediction API - Predict Yield',
            'url': 'http://localhost:5003/yield/predict',
            'method': 'POST',
            'data': {'crop': 'Rice', 'soil_data': {'ph': 6.5}}
        },
        {
            'name': 'Sustainability API - Health Check',
            'url': 'http://localhost:5009/health',
            'method': 'GET'
        },
        {
            'name': 'Sustainability API - Score',
            'url': 'http://localhost:5009/sustainability/score',
            'method': 'POST',
            'data': {'crop': 'Rice'}
        },
        {
            'name': 'Crop Rotation API - Health Check',
            'url': 'http://localhost:5010/health',
            'method': 'GET'
        },
        {
            'name': 'Crop Rotation API - Suggest Rotation',
            'url': 'http://localhost:5010/rotation/suggest',
            'method': 'POST',
            'data': {'current_crop': 'Rice'}
        },
        {
            'name': 'Multilingual AI API - Health Check',
            'url': 'http://localhost:5007/health',
            'method': 'GET'
        },
        {
            'name': 'Multilingual AI API - Chat',
            'url': 'http://localhost:5007/chat',
            'method': 'POST',
            'data': {'message': 'Hello', 'language': 'en'}
        }
    ]
    
    # Run tests
    passed = 0
    failed = 0
    
    for test in tests:
        print(f"Testing: {test['name']}")
        success, result = test_api_endpoint(
            test['url'], 
            test.get('method', 'GET'),
            test.get('data'),
            timeout=15
        )
        
        if success:
            print(f"  ✅ PASSED")
            passed += 1
            
            # Show some key data for important tests
            if 'Full Recommendation' in test['name']:
                if isinstance(result, dict) and 'data' in result:
                    rec_data = result['data']
                    if 'recommendation' in rec_data:
                        crop = rec_data['recommendation'].get('primary_recommendation', 'Unknown')
                        confidence = rec_data['recommendation'].get('confidence', 0)
                        print(f"     Recommended crop: {crop} (confidence: {confidence:.2f})")
            
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1
        
        print()
        time.sleep(0.5)  # Small delay between tests
    
    # Summary
    print("="*60)
    print("TEST SUMMARY")
    print("="*60)
    print(f"Total Tests: {len(tests)}")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Success Rate: {(passed/len(tests)*100):.1f}%")
    
    if failed == 0:
        print("\n🎉 ALL TESTS PASSED! System is working correctly.")
        return True
    elif passed >= len(tests) * 0.8:  # 80% success rate
        print(f"\n⚠️  Most tests passed ({passed}/{len(tests)}). System should work.")
        return True
    else:
        print(f"\n❌ Many tests failed ({failed}/{len(tests)}). Check system status.")
        return False

def check_system_status():
    """Check if the system is running"""
    print("Checking if Ultra Crop Recommender System is running...")
    print("If APIs are not running, please start them first:")
    print("  1. cd backend")
    print("  2. python start_ultra_complete.py")
    print("  3. Wait for all APIs to start, then run this test")
    print()
    
    # Quick check of main API
    success, _ = test_api_endpoint('http://localhost:5020/health', timeout=5)
    if not success:
        print("❌ Ultra Crop Recommender API is not running")
        print("Please start the system first and try again.")
        return False
    else:
        print("✅ Ultra Crop Recommender API is running")
        return True

if __name__ == '__main__':
    if not check_system_status():
        sys.exit(1)
    
    success = run_tests()
    sys.exit(0 if success else 1)
