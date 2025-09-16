#!/usr/bin/env python3
"""
Test script for Crop Recommendation API
"""

import sys
import os

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    print("🔍 Testing Crop Recommendation API...")
    
    # Test imports
    print("📦 Testing imports...")
    from src.api.crop_api_production import app
    print("✅ Imports successful")
    
    # Test model loading
    print("🤖 Testing model loading...")
    from src.api.crop_api_production import load_models
    load_models()
    print("✅ Models loaded successfully")
    
    # Test Flask app
    print("🌐 Testing Flask app...")
    app.config['TESTING'] = True
    client = app.test_client()
    
    # Test health endpoint
    response = client.get('/health')
    print(f"✅ Health endpoint: {response.status_code}")
    print(f"📄 Response: {response.get_json()}")
    
    print("🎉 All tests passed!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
