#!/usr/bin/env python3
"""
Test script to verify API endpoints for AI Yield Advisory
"""

import requests
import json

# Production URLs with /api prefix
YIELD_PREDICTION_URL = "https://sih2025-integrated-api-273619012635.us-central1.run.app/api"
WEATHER_URL = "https://sih2025-weather-api-273619012635.us-central1.run.app/api"
SOIL_URL = "https://sih2025-soil-api-273619012635.us-central1.run.app/api"

def test_api_endpoint(url, method="GET", data=None, expected_status=200):
    """Test an API endpoint and return the result"""
    try:
        if method == "GET":
            response = requests.get(url, timeout=10)
        elif method == "POST":
            response = requests.post(url, json=data, timeout=10)
        
        print(f"✅ {method} {url}")
        print(f"   Status: {response.status_code}")
        
        if response.status_code == expected_status:
            try:
                result = response.json()
                print(f"   Response: {json.dumps(result, indent=2)[:200]}...")
                return True, result
            except:
                print(f"   Response: {response.text[:200]}...")
                return True, response.text
        else:
            print(f"   ❌ Expected {expected_status}, got {response.status_code}")
            if response.status_code != 404:
                try:
                    error_result = response.json()
                    print(f"   Error: {json.dumps(error_result, indent=2)[:200]}...")
                except:
                    print(f"   Error: {response.text[:200]}...")
            return False, None
            
    except Exception as e:
        print(f"❌ {method} {url}")
        print(f"   Error: {str(e)}")
        return False, None

def main():
    print("🧪 Testing AI Yield Advisory API Endpoints")
    print("=" * 60)
    
    # Test health endpoints
    print("\n1. Testing Health Endpoints:")
    test_api_endpoint(f"{YIELD_PREDICTION_URL}/health")
    test_api_endpoint(f"{WEATHER_URL}/health")
    test_api_endpoint(f"{SOIL_URL}/health")
    
    # Test yield prediction endpoint
    print("\n2. Testing Yield Prediction Endpoint:")
    yield_data = {
        "crop_name": "Rice",
        "area_hectares": 1.0,
        "soil_ph": 6.5,
        "soil_moisture": 50.0,
        "temperature": 25.0,
        "rainfall": 1000.0,
        "season": "Kharif"
    }
    test_api_endpoint(f"{YIELD_PREDICTION_URL}/predict", "POST", yield_data)
    
    # Test weather endpoint
    print("\n3. Testing Weather Endpoint:")
    test_api_endpoint(f"{WEATHER_URL}/weather/current?lat=28.6139&lon=77.2090")
    
    # Test soil endpoint
    print("\n4. Testing Soil Endpoint:")
    test_api_endpoint(f"{SOIL_URL}/soil/current?lat=28.6139&lon=77.2090")
    
    # Test alternative endpoints
    print("\n5. Testing Alternative Endpoints:")
    test_api_endpoint(f"{YIELD_PREDICTION_URL}/yield/predict", "POST", yield_data)
    test_api_endpoint(f"{WEATHER_URL}/current?lat=28.6139&lon=77.2090")
    test_api_endpoint(f"{SOIL_URL}/current?lat=28.6139&lon=77.2090")
    
    print("\n" + "=" * 60)
    print("✅ Testing completed!")

if __name__ == "__main__":
    main()
