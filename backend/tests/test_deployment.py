#!/usr/bin/env python3
"""
Test script to check if the Crop Recommendation API is deployed and working
"""

import requests
import json
import time

def test_api_health(base_url):
    """Test the health endpoint"""
    try:
        response = requests.get(f"{base_url}/health", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Health check passed!")
            print(f"   Status: {data.get('status')}")
            print(f"   Message: {data.get('message')}")
            print(f"   Models loaded: {data.get('models_loaded')}")
            return True
        else:
            print(f"❌ Health check failed with status: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check failed: {str(e)}")
        return False

def test_crop_recommendation(base_url):
    """Test the crop recommendation endpoint"""
    try:
        test_data = {
            "N": 90,
            "P": 42,
            "K": 43,
            "temperature": 20.88,
            "humidity": 82.00,
            "ph": 6.50,
            "rainfall": 202.94,
            "model_type": "rf"
        }
        
        response = requests.post(
            f"{base_url}/recommend",
            json=test_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Crop recommendation test passed!")
            print(f"   Recommended crop: {data.get('recommended_crop')}")
            print(f"   Confidence: {data.get('confidence')}")
            print(f"   Model type: {data.get('model_type')}")
            return True
        else:
            print(f"❌ Crop recommendation test failed with status: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Crop recommendation test failed: {str(e)}")
        return False

def main():
    print("🧪 Testing Crop Recommendation API Deployment...")
    print("=" * 50)
    
    # Common Cloud Run URLs to test
    possible_urls = [
        "https://crop-recommendation-api-xxxxxxxx-uc.a.run.app",  # This will be replaced with actual URL
        "https://crop-recommendation-api-xxxxxxxx-uc.a.run.app",  # Alternative format
    ]
    
    # Try to get the actual URL from gcloud
    import subprocess
    try:
        result = subprocess.run(
            ["gcloud", "run", "services", "describe", "crop-recommendation-api", 
             "--region", "us-central1", "--format", "value(status.url)"],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0 and result.stdout.strip():
            actual_url = result.stdout.strip()
            possible_urls.insert(0, actual_url)
            print(f"🔍 Found service URL: {actual_url}")
    except Exception as e:
        print(f"⚠️  Could not get service URL automatically: {e}")
    
    print("\n📋 Testing possible URLs...")
    
    for i, url in enumerate(possible_urls):
        if "xxxxxxxx" in url:
            print(f"⏭️  Skipping placeholder URL {i+1}")
            continue
            
        print(f"\n🌐 Testing URL {i+1}: {url}")
        print("-" * 30)
        
        # Test health endpoint
        if test_api_health(url):
            # Test crop recommendation
            if test_crop_recommendation(url):
                print(f"\n🎉 SUCCESS! Your API is working at: {url}")
                print(f"📱 Update your Flutter app to use this URL: {url}")
                return
            else:
                print(f"⚠️  Health check passed but crop recommendation failed")
        else:
            print(f"❌ URL {i+1} is not responding")
    
    print(f"\n❌ None of the URLs are working.")
    print(f"💡 Please check:")
    print(f"   1. The deployment is still in progress (can take 5-10 minutes)")
    print(f"   2. Check Google Cloud Console: https://console.cloud.google.com/run")
    print(f"   3. Check logs: gcloud logs read --service=crop-recommendation-api --region=us-central1")

if __name__ == "__main__":
    main()
