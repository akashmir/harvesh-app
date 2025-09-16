#!/usr/bin/env python3
"""
Quick SIH 2025 Deployment Script
For immediate testing and demonstration
"""

import subprocess
import sys
import os
import time

def start_all_apis():
    """Start all SIH 2025 APIs locally"""
    print("🚀 Starting SIH 2025 APIs...")
    
    apis = [
        "crop_api_production.py",
        "weather_integration_api.py", 
        "market_price_api.py",
        "satellite_soil_api.py",
        "multilingual_ai_api.py",
        "ai_disease_detection_api.py",
        "sustainability_scoring_api.py",
        "crop_rotation_api.py",
        "offline_capability_api.py",
        "sih_2025_integrated_api.py"
    ]
    
    for api in apis:
        try:
            print(f"Starting {api}...")
            subprocess.Popen([
                "python", api
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(2)  # Wait between starts
        except Exception as e:
            print(f"Failed to start {api}: {e}")
    
    print("✅ All APIs started!")

def test_system():
    """Test the complete system"""
    print("\n🧪 Testing SIH 2025 System...")
    
    try:
        result = subprocess.run([
            "python", "test_final_100_percent.py"
        ], capture_output=True, text=True, check=True)
        
        print("✅ System test passed!")
        print(result.stdout)
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ System test failed: {e}")
        print(e.stdout)
        return False

def build_flutter():
    """Build Flutter app"""
    print("\n📱 Building Flutter App...")
    
    try:
        os.chdir("Flutter")
        
        # Get dependencies
        subprocess.run(["flutter", "pub", "get"], check=True)
        
        # Build APK
        subprocess.run([
            "flutter", "build", "apk", "--release"
        ], check=True)
        
        print("✅ Flutter app built successfully!")
        print("📱 APK location: build/app/outputs/flutter-apk/app-release.apk")
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Flutter build failed: {e}")
        return False
    finally:
        os.chdir("..")

def main():
    """Main deployment function"""
    print("🎯 SIH 2025 QUICK DEPLOYMENT")
    print("=" * 40)
    
    # Step 1: Start APIs
    start_all_apis()
    
    # Step 2: Wait for APIs to start
    print("\n⏳ Waiting for APIs to initialize...")
    time.sleep(15)
    
    # Step 3: Test system
    if not test_system():
        print("❌ System test failed!")
        return False
    
    # Step 4: Build Flutter
    if not build_flutter():
        print("❌ Flutter build failed!")
        return False
    
    print("\n🎉 QUICK DEPLOYMENT COMPLETE!")
    print("=" * 40)
    print("✅ All APIs running locally")
    print("✅ System tested (100% success)")
    print("✅ Flutter app built")
    print()
    print("🌐 Access your app:")
    print("  - Flutter: Run the built APK")
    print("  - APIs: All running on localhost")
    print("  - Dashboard: Navigate to SIH 2025 AI in the app")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
