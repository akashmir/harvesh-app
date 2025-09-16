#!/usr/bin/env python3
"""
Test Weather Integration API
"""

import requests
import json
import time

def test_weather_integration_api():
    """Test all weather integration API endpoints"""
    base_url = "http://localhost:5005"
    
    print("🌤️ Weather Integration API Test")
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
    
    # Test get current weather
    print("\n🔍 Testing Current Weather")
    try:
        response = requests.get(f"{base_url}/weather/current?location=Delhi&lat=28.6139&lon=77.2090", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Current weather retrieved")
            print(f"Location: {data['data']['location']}")
            print(f"Temperature: {data['data']['temperature']}°C")
            print(f"Humidity: {data['data']['humidity']}%")
            print(f"Condition: {data['data']['weather_condition']}")
        else:
            print("❌ Failed to get current weather")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test weather forecast
    print("\n🔍 Testing Weather Forecast")
    try:
        response = requests.get(f"{base_url}/weather/forecast?location=Delhi&days=5", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Weather forecast retrieved")
            print(f"Location: {data['data']['location']}")
            print(f"Total days: {data['data']['total_days']}")
            if data['data']['forecasts']:
                first_forecast = data['data']['forecasts'][0]
                print(f"First forecast: {first_forecast['date']} - {first_forecast['temperature_max']}°/{first_forecast['temperature_min']}°")
        else:
            print("❌ Failed to get weather forecast")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test weather recommendations
    print("\n🔍 Testing Weather Recommendations")
    weather_data = {
        "temperature": 28.5,
        "humidity": 65.0,
        "wind_speed": 12.0,
        "precipitation": 5.0
    }
    
    try:
        response = requests.post(f"{base_url}/weather/recommendations", json={"weather_data": weather_data}, timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Weather recommendations retrieved")
            recommendations = data['data']['recommendations']
            print(f"Condition: {recommendations['condition']}")
            print(f"Description: {recommendations['description']}")
            print(f"Crops: {recommendations['crops']}")
            print(f"Irrigation: {recommendations['irrigation']}")
        else:
            print("❌ Failed to get weather recommendations")
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test weather alerts
    print("\n🔍 Testing Weather Alerts")
    try:
        response = requests.get(f"{base_url}/weather/alerts?location=Delhi", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Weather alerts retrieved")
            print(f"Location: {data['data']['location']}")
            print(f"Total alerts: {data['data']['total_alerts']}")
            if data['data']['alerts']:
                first_alert = data['data']['alerts'][0]
                print(f"First alert: {first_alert['alert_type']} - {first_alert['severity']}")
        else:
            print("❌ Failed to get weather alerts")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test weather history
    print("\n🔍 Testing Weather History")
    try:
        response = requests.get(f"{base_url}/weather/history?days=7", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Weather history retrieved")
            print(f"Total records: {data['data']['total_records']}")
            if data['data']['weather_history']:
                latest = data['data']['weather_history'][0]
                print(f"Latest: {latest['location']} - {latest['temperature']}°C")
        else:
            print("❌ Failed to get weather history")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test weather analytics
    print("\n🔍 Testing Weather Analytics")
    try:
        response = requests.get(f"{base_url}/weather/analytics", timeout=10)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            analytics = data['data']
            print("✅ Weather analytics retrieved")
            temp_analytics = analytics['temperature_analytics']
            print(f"Avg temperature: {temp_analytics['average']}°C")
            print(f"Min temperature: {temp_analytics['minimum']}°C")
            print(f"Max temperature: {temp_analytics['maximum']}°C")
            print(f"Record count: {temp_analytics['record_count']}")
        else:
            print("❌ Failed to get weather analytics")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print("\n" + "=" * 50)
    print("🎯 Weather Integration API Test Complete!")

if __name__ == "__main__":
    test_weather_integration_api()
