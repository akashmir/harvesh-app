"""
Test script for Simple Crop Recommendation API
"""

import urllib.request
import urllib.parse
import json

API_BASE_URL = "http://localhost:5000"

def test_health_check():
    """Test health check endpoint"""
    print("Testing health check...")
    try:
        with urllib.request.urlopen(f"{API_BASE_URL}/health") as response:
            data = json.loads(response.read().decode())
            print(f"Status Code: {response.status}")
            print(f"Response: {json.dumps(data, indent=2)}")
            return response.status == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_crop_recommendation():
    """Test crop recommendation endpoint"""
    print("\nTesting crop recommendation...")
    
    # Test data
    test_data = {
        "N": 90,
        "P": 42,
        "K": 43,
        "temperature": 20.88,
        "humidity": 82.00,
        "ph": 6.50,
        "rainfall": 202.94
    }
    
    try:
        data = json.dumps(test_data).encode('utf-8')
        req = urllib.request.Request(
            f"{API_BASE_URL}/recommend",
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            print(f"Status Code: {response.status}")
            print(f"Response: {json.dumps(result, indent=2)}")
            
            if response.status == 200:
                print(f"✅ Recommended crop: {result['recommended_crop']}")
                print(f"✅ Confidence: {result['confidence']:.4f}")
                return True
            else:
                print(f"❌ Error: {result.get('error', 'Unknown error')}")
                return False
                
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_get_crops():
    """Test get available crops endpoint"""
    print("\nTesting get crops...")
    try:
        with urllib.request.urlopen(f"{API_BASE_URL}/crops") as response:
            result = json.loads(response.read().decode())
            print(f"Status Code: {response.status}")
            
            if response.status == 200:
                print(f"✅ Total crops available: {result['total_crops']}")
                print(f"✅ First 5 crops: {result['crops'][:5]}")
                return True
            else:
                print(f"❌ Error: {result.get('error', 'Unknown error')}")
                return False
                
    except Exception as e:
        print(f"Error: {e}")
        return False

def run_all_tests():
    """Run all tests"""
    print("=== Simple Crop Recommendation API Tests ===\n")
    
    tests = [
        ("Health Check", test_health_check),
        ("Get Crops", test_get_crops),
        ("Crop Recommendation", test_crop_recommendation),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n{'='*50}")
        print(f"Running: {test_name}")
        print('='*50)
        
        if test_func():
            passed += 1
            print(f"✅ {test_name} PASSED")
        else:
            print(f"❌ {test_name} FAILED")
    
    print(f"\n{'='*50}")
    print(f"Test Results: {passed}/{total} tests passed")
    print('='*50)
    
    return passed == total

if __name__ == "__main__":
    print("Make sure the API server is running on http://localhost:5000")
    print("Start the server with: python simple_api.py")
    print("\nWaiting 3 seconds before starting tests...")
    import time
    time.sleep(3)
    
    run_all_tests()
