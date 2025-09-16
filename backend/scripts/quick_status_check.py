#!/usr/bin/env python3
"""
Quick Status Check for SIH 2025 APIs
"""

import requests
import time

def check_api_status():
    """Check status of all SIH 2025 APIs"""
    apis = {
        'Crop API': 'http://localhost:8080/health',
        'Weather API': 'http://localhost:5005/health',
        'Market API': 'http://localhost:5004/health',
        'Soil API': 'http://localhost:5006/health',
        'Multilingual API': 'http://localhost:5007/health',
        'Disease API': 'http://localhost:5008/health',
        'Sustainability API': 'http://localhost:5009/health',
        'Rotation API': 'http://localhost:5010/health',
        'Offline API': 'http://localhost:5011/health',
        'Integrated API': 'http://localhost:5012/health'
    }
    
    print("🔍 SIH 2025 API Status Check")
    print("=" * 50)
    
    healthy_count = 0
    total_count = len(apis)
    
    for name, url in apis.items():
        try:
            response = requests.get(url, timeout=3)
            if response.status_code == 200:
                print(f"✅ {name}: HEALTHY")
                healthy_count += 1
            else:
                print(f"❌ {name}: HTTP {response.status_code}")
        except requests.exceptions.ConnectionError:
            print(f"❌ {name}: NOT RUNNING")
        except Exception as e:
            print(f"❌ {name}: ERROR - {str(e)[:50]}")
    
    print("=" * 50)
    success_rate = (healthy_count / total_count) * 100
    print(f"📊 Status: {healthy_count}/{total_count} APIs healthy ({success_rate:.1f}%)")
    
    if success_rate == 100:
        print("🎉 100% SUCCESS! ALL APIs ARE RUNNING!")
    elif success_rate >= 80:
        print("✅ EXCELLENT! Most APIs are running!")
    elif success_rate >= 60:
        print("⚠️ GOOD! Some APIs need attention.")
    else:
        print("❌ NEEDS WORK! Many APIs are not running.")
    
    return success_rate

if __name__ == "__main__":
    check_api_status()
