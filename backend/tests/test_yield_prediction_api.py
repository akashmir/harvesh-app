#!/usr/bin/env python3
"""
Test Yield Prediction API
"""

import requests
import json
import time

def test_yield_prediction_api():
    """Test all yield prediction API endpoints"""
    base_url = "http://localhost:5003"
    
    print("🌾 Yield Prediction API Test")
    print("=" * 50)
    
    # Test health check
    print("\n🔍 Testing Health Check")
    try:
        response = requests.get(f"{base_url}/health", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ Health check passed")
            print(f"Response: {response.json()}")
        else:
            print("❌ Health check failed")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test get available crops
    print("\n🔍 Testing Available Crops")
    try:
        response = requests.get(f"{base_url}/crops", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Crops loaded")
            print(f"Available crops: {data['data']['total_crops']}")
            # Show first 5 crops
            for i, (crop, info) in enumerate(data['data']['crops'].items()):
                if i < 5:
                    print(f"  - {crop}: {info['avg']} kg/ha average")
        else:
            print("❌ Failed to load crops")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test yield prediction
    print("\n🔍 Testing Yield Prediction")
    prediction_data = {
        "crop_name": "Rice",
        "area_hectares": 2.0,
        "soil_ph": 6.8,
        "soil_moisture": 65.0,
        "temperature": 28.0,
        "rainfall": 1200.0,
        "season": "Kharif"
    }
    
    try:
        response = requests.post(f"{base_url}/predict", json=prediction_data, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Yield prediction successful")
            print(f"Predicted Yield: {data['data']['predicted_yield']} kg")
            print(f"Yield per Hectare: {data['data']['yield_per_hectare']} kg/ha")
            print(f"Confidence Score: {data['data']['confidence_score']}")
            print(f"Prediction ID: {data['data']['prediction_id']}")
        else:
            print("❌ Failed to predict yield")
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test get predictions
    print("\n🔍 Testing Get Predictions")
    try:
        response = requests.get(f"{base_url}/predictions", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Predictions retrieved")
            print(f"Total predictions: {data['data']['total_predictions']}")
            if data['data']['predictions']:
                latest = data['data']['predictions'][0]
                print(f"Latest prediction: {latest['crop_name']} - {latest['predicted_yield']} kg")
        else:
            print("❌ Failed to get predictions")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test add historical data
    print("\n🔍 Testing Add Historical Data")
    historical_data = {
        "field_id": "test_field_1",
        "crop_name": "Rice",
        "actual_yield": 8000.0,
        "area_hectares": 2.0,
        "planting_date": "2024-06-01",
        "harvesting_date": "2024-10-15",
        "soil_ph": 6.5,
        "soil_moisture": 60.0,
        "avg_temperature": 28.0,
        "total_rainfall": 1100.0,
        "season": "Kharif",
        "notes": "Test historical data"
    }
    
    try:
        response = requests.post(f"{base_url}/historical", json=historical_data, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Historical data added")
            print(f"Yield ID: {data['data']['yield_id']}")
            print(f"Yield per hectare: {data['data']['yield_per_hectare']} kg/ha")
        else:
            print("❌ Failed to add historical data")
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test get historical data
    print("\n🔍 Testing Get Historical Data")
    try:
        response = requests.get(f"{base_url}/historical", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Historical data retrieved")
            print(f"Total records: {data['data']['total_records']}")
            if data['data']['historical_yields']:
                latest = data['data']['historical_yields'][0]
                print(f"Latest record: {latest['crop_name']} - {latest['yield_per_hectare']} kg/ha")
        else:
            print("❌ Failed to get historical data")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test analytics
    print("\n🔍 Testing Analytics")
    try:
        response = requests.get(f"{base_url}/analytics", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            analytics = data['data']['analytics']
            print("✅ Analytics retrieved")
            print(f"Total records: {analytics.get('total_records', 0)}")
            print(f"Average yield: {analytics.get('average_yield_per_hectare', 0)} kg/ha")
            print(f"Max yield: {analytics.get('max_yield_per_hectare', 0)} kg/ha")
            print(f"Total area: {analytics.get('total_area_hectares', 0)} ha")
        else:
            print("❌ Failed to get analytics")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test yield factors
    print("\n🔍 Testing Yield Factors")
    try:
        response = requests.get(f"{base_url}/factors", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Yield factors retrieved")
            factors = data['data']['yield_factors']
            print(f"Available factors: {len(factors)}")
            for factor, config in factors.items():
                print(f"  - {factor}: weight {config['weight']}")
        else:
            print("❌ Failed to get yield factors")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print("\n" + "=" * 50)
    print("🎯 Yield Prediction API Test Complete!")

if __name__ == "__main__":
    test_yield_prediction_api()
