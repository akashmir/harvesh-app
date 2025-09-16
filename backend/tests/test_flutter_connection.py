#!/usr/bin/env python3
"""
Test Flutter app connection to Crop Calendar API
"""

import requests
import json

def test_flutter_connection():
    """Test the endpoints that Flutter app will use"""
    base_url = "http://10.0.2.2:5001"  # Android emulator URL
    
    print("🧪 Testing Flutter App Connection")
    print("=" * 50)
    
    # Test endpoints that Flutter will call
    endpoints = [
        ("/health", "Health Check"),
        ("/calendar/current", "Current Month"),
        ("/calendar/yearly/summary", "Yearly Summary"),
        ("/calendar/seasons", "Seasons"),
        ("/calendar/season/Kharif", "Kharif Season"),
    ]
    
    for endpoint, description in endpoints:
        print(f"\n🔍 Testing: {description}")
        print(f"URL: {base_url}{endpoint}")
        
        try:
            response = requests.get(f"{base_url}{endpoint}", timeout=10)
            print(f"Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print("✅ Success!")
                
                # Show response size
                response_size = len(json.dumps(data))
                print(f"Response size: {response_size} bytes")
                
                # Show key data
                if 'data' in data:
                    if 'month_name' in data['data']:
                        print(f"Current month: {data['data']['month_name']}")
                    elif 'yearly_summary' in data['data']:
                        print(f"Months available: {len(data['data']['yearly_summary'])}")
                    elif 'seasons' in data['data']:
                        print(f"Seasons: {list(data['data']['seasons'].keys())}")
                    elif 'crops' in data['data']:
                        print(f"Crops: {len(data['data']['crops'])}")
                        
            else:
                print(f"❌ Failed: {response.text}")
                
        except requests.exceptions.ConnectionError:
            print("❌ Connection Error!")
            print("   Make sure API server is running on 0.0.0.0:5001")
        except requests.exceptions.Timeout:
            print("❌ Timeout Error!")
            print("   Request took too long")
        except Exception as e:
            print(f"❌ Error: {e}")
    
    print("\n" + "=" * 50)
    print("🎯 Connection Test Complete!")
    print("\n💡 If all tests pass, Flutter app should work!")
    print("💡 If connection errors, check API server binding")

if __name__ == "__main__":
    test_flutter_connection()
