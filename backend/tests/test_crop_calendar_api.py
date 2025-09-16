#!/usr/bin/env python3
"""
Test script for Crop Calendar API
"""

import requests
import json
from datetime import datetime

# API base URL
BASE_URL = "http://localhost:5001"

def test_api_endpoint(endpoint, description):
    """Test an API endpoint and print results"""
    print(f"\n{'='*50}")
    print(f"Testing: {description}")
    print(f"Endpoint: {endpoint}")
    print(f"{'='*50}")
    
    try:
        response = requests.get(f"{BASE_URL}{endpoint}", timeout=10)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Success!")
            print(f"Response: {json.dumps(data, indent=2)}")
        else:
            print("❌ Failed!")
            print(f"Error: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error!")
        print("Make sure the Crop Calendar API is running on port 5001")
    except Exception as e:
        print(f"❌ Error: {e}")

def main():
    print("🌱 Crop Calendar API Test Suite")
    print("=" * 50)
    
    # Test endpoints
    endpoints = [
        ("/health", "Health Check"),
        ("/calendar/current", "Current Month Schedule"),
        ("/calendar/yearly", "Yearly Calendar"),
        ("/calendar/seasons", "Available Seasons"),
        ("/calendar/crops", "All Crops"),
        ("/calendar/crop/rice", "Rice Crop Schedule"),
        ("/calendar/season/Kharif", "Kharif Season Crops"),
        ("/calendar/month/6", "June Schedule"),
    ]
    
    for endpoint, description in endpoints:
        test_api_endpoint(endpoint, description)
    
    print(f"\n{'='*50}")
    print("🎉 Test Suite Complete!")
    print("=" * 50)

if __name__ == "__main__":
    main()
