#!/usr/bin/env python3
"""
Test the deployed Crop Recommendation API
"""

import requests
import json
import time

def test_api():
    base_url = "https://crop-recommendation-api-273619012635.us-central1.run.app"
    
    print("🧪 Testing Crop Recommendation API...")
    print(f"🌐 URL: {base_url}")
    print("=" * 50)
    
    # Test 1: Health Check
    print("\n1️⃣ Testing Health Check...")
    try:
        response = requests.get(f"{base_url}/health", timeout=30)
        print(f"   Status Code: {response.status_code}")
        if response.status_code == 200:
            health_data = response.json()
            print(f"   ✅ Health Check Passed! API is live.")
            print(f"   Model Loaded: {health_data.get('model_loaded', 'Unknown')}")
            print(f"   Total Crops: {health_data.get('total_crops', 'Unknown')}")
        else:
            print(f"   ❌ Health Check Failed: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ Health Check Error: {str(e)}")
        return False
    
    # Test 2: Crop Recommendation
    print("\n2️⃣ Testing Crop Recommendation...")
    try:
        test_data = {
            "N": 90,
            "P": 42,
            "K": 43,
            "temperature": 20.88,
            "humidity": 82.00,
            "ph": 6.50,
            "rainfall": 202.94
        }
        
        response = requests.post(
            f"{base_url}/recommend",
            json=test_data,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        print(f"   Status Code: {response.status_code}")
        if response.status_code == 200:
            response_data = response.json()
            
            print(f"   ✅ Crop Recommendation Passed!")
            print(f"   Recommended Crop: {response_data.get('recommended_crop', 'Unknown')}")
            print(f"   Confidence: {response_data.get('confidence', 'Unknown')}")
            print(f"   Model Type: {response_data.get('model_type', 'Unknown')}")
            print(f"   Top 3 Predictions:")
            for i, pred in enumerate(response_data.get('top_3_predictions', []), 1):
                print(f"     {i}. {pred['crop']} (confidence: {pred['confidence']:.3f})")
        else:
            print(f"   ❌ Crop Recommendation Failed: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ Crop Recommendation Error: {str(e)}")
        return False
    
    print(f"\n🎉 SUCCESS! Your API is working perfectly!")
    print(f"📱 Update your Flutter app to use: {base_url}")
    return True

if __name__ == "__main__":
    test_api()