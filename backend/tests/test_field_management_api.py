#!/usr/bin/env python3
"""
Test Field Management API
"""

import requests
import json
import time

def test_field_management_api():
    """Test all field management API endpoints"""
    base_url = "http://localhost:5002"
    
    print("🌾 Field Management API Test")
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
    
    # Test soil types
    print("\n🔍 Testing Soil Types")
    try:
        response = requests.get(f"{base_url}/soil-types", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Soil types loaded")
            print(f"Available soil types: {len(data['data']['soil_types'])}")
            for soil_type, info in data['data']['soil_types'].items():
                print(f"  - {info['name']}: {info['description']}")
        else:
            print("❌ Failed to load soil types")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test create field
    print("\n🔍 Testing Create Field")
    field_data = {
        "name": "Test Field 1",
        "description": "A test field for API testing",
        "area_hectares": 2.5,
        "latitude": 28.6139,
        "longitude": 77.2090,
        "soil_type": "loamy",
        "soil_ph": 6.8,
        "soil_moisture": 65.0,
        "elevation": 200.0
    }
    
    try:
        response = requests.post(f"{base_url}/fields", json=field_data, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 201:
            data = response.json()
            field_id = data['data']['id']
            print("✅ Field created successfully")
            print(f"Field ID: {field_id}")
            print(f"Field Name: {data['data']['name']}")
        else:
            print("❌ Failed to create field")
            print(f"Error: {response.text}")
            return
    except Exception as e:
        print(f"❌ Error: {e}")
        return
    
    # Test get all fields
    print("\n🔍 Testing Get All Fields")
    try:
        response = requests.get(f"{base_url}/fields", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Fields retrieved successfully")
            print(f"Total fields: {data['data']['total_fields']}")
            for field in data['data']['fields']:
                print(f"  - {field['name']}: {field['area_hectares']} ha")
        else:
            print("❌ Failed to get fields")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test get specific field
    print(f"\n🔍 Testing Get Field Details")
    try:
        response = requests.get(f"{base_url}/fields/{field_id}", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Field details retrieved")
            field = data['data']['field']
            print(f"Field: {field['name']}")
            print(f"Area: {field['area_hectares']} ha")
            print(f"Location: {field['latitude']}, {field['longitude']}")
            print(f"Soil: {field['soil_type']} (pH: {field['soil_ph']})")
            print(f"Crop History: {len(data['data']['crop_history'])} records")
        else:
            print("❌ Failed to get field details")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test add crop to field
    print(f"\n🔍 Testing Add Crop to Field")
    crop_data = {
        "crop_name": "Rice",
        "planting_date": "2024-09-01",
        "harvesting_date": "2024-12-15",
        "yield_kg": 1500.0,
        "notes": "Test rice crop for API testing"
    }
    
    try:
        response = requests.post(f"{base_url}/fields/{field_id}/crops", json=crop_data, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 201:
            data = response.json()
            crop_id = data['data']['crop_id']
            print("✅ Crop added successfully")
            print(f"Crop ID: {crop_id}")
            print(f"Crop: {data['data']['crop_name']}")
        else:
            print("❌ Failed to add crop")
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test field recommendations
    print(f"\n🔍 Testing Field Recommendations")
    try:
        response = requests.get(f"{base_url}/fields/{field_id}/recommendations", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Recommendations generated")
            recommendations = data['data']['recommendations']
            print(f"Recommended crops: {len(recommendations['all_recommendations'])}")
            print(f"Top recommendations: {recommendations['all_recommendations'][:5]}")
            if recommendations['avoid_crops']:
                print(f"Avoid crops: {recommendations['avoid_crops']}")
        else:
            print("❌ Failed to get recommendations")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test nearby fields
    print(f"\n🔍 Testing Nearby Fields")
    try:
        response = requests.get(f"{base_url}/fields/nearby?latitude=28.6139&longitude=77.2090&radius=10", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Nearby fields retrieved")
            print(f"Found {data['data']['total_found']} fields within 10km")
            for field in data['data']['nearby_fields']:
                print(f"  - {field['name']}: {field['distance_km']} km away")
        else:
            print("❌ Failed to get nearby fields")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test update field
    print(f"\n🔍 Testing Update Field")
    update_data = {
        "name": "Updated Test Field",
        "description": "Updated description",
        "soil_moisture": 70.0
    }
    
    try:
        response = requests.put(f"{base_url}/fields/{field_id}", json=update_data, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Field updated successfully")
            print(f"Updated name: {data['data']['name']}")
            print(f"Updated moisture: {data['data']['soil_moisture']}%")
        else:
            print("❌ Failed to update field")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test delete field
    print(f"\n🔍 Testing Delete Field")
    try:
        response = requests.delete(f"{base_url}/fields/{field_id}", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ Field deleted successfully")
        else:
            print("❌ Failed to delete field")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print("\n" + "=" * 50)
    print("🎯 Field Management API Test Complete!")

if __name__ == "__main__":
    test_field_management_api()
