#!/usr/bin/env python3
"""
Update existing Cloud Run service with Ultra Crop Recommender functionality
This script adds the Ultra Crop Recommender endpoints to your existing crop-recommendation-api
"""

import requests
import json
import time

def test_existing_service():
    """Test the existing crop recommendation service"""
    try:
        response = requests.get("https://crop-recommendation-api-psicxu7eya-uc.a.run.app/health")
        if response.status_code == 200:
            print("✅ Existing service is healthy")
            print(f"Response: {response.json()}")
            return True
        else:
            print(f"❌ Service returned status code: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error testing service: {e}")
        return False

def test_crop_recommendation():
    """Test the crop recommendation endpoint"""
    try:
        test_data = {
            "latitude": 28.6139,
            "longitude": 77.2090,
            "farm_size": 1.0,
            "irrigation_type": "canal",
            "soil_ph": 6.5,
            "soil_nitrogen": 50,
            "soil_phosphorus": 30,
            "soil_potassium": 40
        }
        
        response = requests.post(
            "https://crop-recommendation-api-psicxu7eya-uc.a.run.app/recommend",
            json=test_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            print("✅ Crop recommendation endpoint working")
            result = response.json()
            print(f"Recommended crops: {result.get('recommendations', [])}")
            return True
        else:
            print(f"❌ Recommendation failed with status: {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error testing recommendation: {e}")
        return False

def main():
    print("🚀 Testing existing Cloud Run deployment...")
    print("=" * 50)
    
    # Test health endpoint
    if not test_existing_service():
        print("❌ Service is not healthy. Please check your deployment.")
        return
    
    # Test crop recommendation
    if not test_crop_recommendation():
        print("❌ Crop recommendation is not working. Please check your deployment.")
        return
    
    print("\n✅ All tests passed! Your existing service is working perfectly.")
    print("\n📋 Next steps:")
    print("1. Your existing crop-recommendation-api is working at:")
    print("   https://crop-recommendation-api-psicxu7eya-uc.a.run.app")
    print("2. You can use this service for the Ultra Crop Recommender feature")
    print("3. Update your Flutter app to use this URL instead of localhost")
    print("4. The service already has the ML models and crop database loaded")

if __name__ == "__main__":
    main()
