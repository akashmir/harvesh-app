#!/usr/bin/env python3
"""
Test Market Price API
"""

import requests
import json
import time

def test_market_price_api():
    """Test all market price API endpoints"""
    base_url = "http://localhost:5004"
    
    print("💰 Market Price API Test")
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
                    print(f"  - {crop}: ₹{info['baseline_price']}/kg")
        else:
            print("❌ Failed to load crops")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test get current price
    print("\n🔍 Testing Get Current Price")
    try:
        response = requests.get(f"{base_url}/price/current?crop=Rice&state=Punjab", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Current price retrieved")
            print(f"Crop: {data['data']['crop_name']}")
            print(f"Price: ₹{data['data']['current_price']}/kg")
            print(f"State: {data['data']['state']}")
            print(f"Demand: {data['data']['market_demand']}")
        else:
            print("❌ Failed to get current price")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test price prediction
    print("\n🔍 Testing Price Prediction")
    prediction_data = {
        "crop_name": "Wheat",
        "days_ahead": 30
    }
    
    try:
        response = requests.post(f"{base_url}/price/predict", json=prediction_data, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Price prediction successful")
            print(f"Crop: {data['data']['crop_name']}")
            print(f"Predicted Price: ₹{data['data']['predicted_price']}/kg")
            print(f"Confidence: {data['data']['confidence_score']}")
            print(f"Target Date: {data['data']['target_date']}")
        else:
            print("❌ Failed to predict price")
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test profit calculation
    print("\n🔍 Testing Profit Calculation")
    profit_data = {
        "crop_name": "Rice",
        "yield_kg": 5000.0,
        "area_hectares": 2.0,
        "market_price": 25.0
    }
    
    try:
        response = requests.post(f"{base_url}/profit/calculate", json=profit_data, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Profit calculation successful")
            print(f"Crop: {data['data']['crop_name']}")
            print(f"Total Revenue: ₹{data['data']['total_revenue']}")
            print(f"Total Cost: ₹{data['data']['total_cost']}")
            print(f"Net Profit: ₹{data['data']['net_profit']}")
            print(f"Profit Margin: {data['data']['profit_margin']}%")
        else:
            print("❌ Failed to calculate profit")
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test price history
    print("\n🔍 Testing Price History")
    try:
        response = requests.get(f"{base_url}/prices/history?days=7", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Price history retrieved")
            print(f"Total records: {data['data']['total_records']}")
            if data['data']['price_history']:
                latest = data['data']['price_history'][0]
                print(f"Latest: {latest['crop_name']} - ₹{latest['price_per_kg']}/kg")
        else:
            print("❌ Failed to get price history")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test analytics
    print("\n🔍 Testing Analytics")
    try:
        response = requests.get(f"{base_url}/analytics", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            analytics = data['data']
            print("✅ Analytics retrieved")
            print(f"Price trends: {len(analytics.get('price_trends', []))}")
            print(f"Profit analytics: {len(analytics.get('profit_analytics', []))}")
            insights = analytics.get('insights', {})
            if insights.get('most_profitable_crop'):
                print(f"Most profitable: {insights['most_profitable_crop']}")
            if insights.get('highest_price_crop'):
                print(f"Highest price: {insights['highest_price_crop']}")
        else:
            print("❌ Failed to get analytics")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print("\n" + "=" * 50)
    print("🎯 Market Price API Test Complete!")

if __name__ == "__main__":
    test_market_price_api()
