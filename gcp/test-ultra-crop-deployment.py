#!/usr/bin/env python3
"""
Ultra Crop Recommender - Deployment Test Script
This script tests the deployed ultra crop recommender API
"""

import requests
import json
import time
import sys
from typing import Dict, Any

class UltraCropTester:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'User-Agent': 'UltraCropTester/1.0'
        })
    
    def test_health(self) -> bool:
        """Test the health endpoint"""
        print("🔍 Testing health endpoint...")
        try:
            response = self.session.get(f"{self.base_url}/health", timeout=30)
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Health check passed: {data.get('status', 'unknown')}")
                print(f"   Version: {data.get('version', 'unknown')}")
                print(f"   ML Models Loaded: {data.get('ml_models_loaded', False)}")
                print(f"   Crop Database Loaded: {data.get('crop_database_loaded', False)}")
                return True
            else:
                print(f"❌ Health check failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
        except Exception as e:
            print(f"❌ Health check error: {e}")
            return False
    
    def test_quick_recommendation(self) -> bool:
        """Test the quick recommendation endpoint"""
        print("\n🔍 Testing quick recommendation endpoint...")
        try:
            test_data = {
                "latitude": 28.6139,  # Delhi
                "longitude": 77.2090
            }
            
            response = self.session.post(
                f"{self.base_url}/ultra-recommend/quick",
                json=test_data,
                timeout=60
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    recommendations = data.get('recommendations', [])
                    print(f"✅ Quick recommendation successful: {len(recommendations)} recommendations")
                    for i, rec in enumerate(recommendations[:3], 1):
                        print(f"   {i}. {rec.get('crop_name', 'Unknown')} (Score: {rec.get('score', 0)})")
                    return True
                else:
                    print(f"❌ Quick recommendation failed: {data.get('error', 'Unknown error')}")
                    return False
            else:
                print(f"❌ Quick recommendation failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
        except Exception as e:
            print(f"❌ Quick recommendation error: {e}")
            return False
    
    def test_full_recommendation(self) -> bool:
        """Test the full recommendation endpoint"""
        print("\n🔍 Testing full recommendation endpoint...")
        try:
            test_data = {
                "latitude": 28.6139,  # Delhi
                "longitude": 77.2090,
                "farm_size": 2.5,
                "irrigation_type": "drip",
                "language": "en"
            }
            
            response = self.session.post(
                f"{self.base_url}/ultra-recommend",
                json=test_data,
                timeout=120
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    recommendations = data.get('recommendations', [])
                    print(f"✅ Full recommendation successful: {len(recommendations)} recommendations")
                    
                    # Show top recommendation details
                    if recommendations:
                        top_rec = recommendations[0]
                        print(f"   Top Recommendation: {top_rec.get('crop_name', 'Unknown')}")
                        print(f"   Score: {top_rec.get('score', 0)}")
                        print(f"   Confidence: {top_rec.get('confidence', 0):.2f}")
                        print(f"   Season: {top_rec.get('season', 'Unknown')}")
                        print(f"   Duration: {top_rec.get('duration_days', 0)} days")
                        print(f"   Expected Yield: {top_rec.get('expected_yield', 0)} tons")
                        print(f"   Expected Profit: ₹{top_rec.get('expected_profit', 0):.2f}")
                    
                    return True
                else:
                    print(f"❌ Full recommendation failed: {data.get('error', 'Unknown error')}")
                    return False
            else:
                print(f"❌ Full recommendation failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
        except Exception as e:
            print(f"❌ Full recommendation error: {e}")
            return False
    
    def test_crop_database(self) -> bool:
        """Test the crop database endpoint"""
        print("\n🔍 Testing crop database endpoint...")
        try:
            response = self.session.get(f"{self.base_url}/ultra-recommend/crops", timeout=30)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    crops = data.get('crops', {})
                    print(f"✅ Crop database accessible: {len(crops)} crops available")
                    
                    # Show some crop names
                    crop_names = list(crops.keys())[:5]
                    print(f"   Sample crops: {', '.join(crop_names)}")
                    return True
                else:
                    print(f"❌ Crop database failed: {data.get('error', 'Unknown error')}")
                    return False
            else:
                print(f"❌ Crop database failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
        except Exception as e:
            print(f"❌ Crop database error: {e}")
            return False
    
    def test_performance(self) -> bool:
        """Test API performance"""
        print("\n🔍 Testing API performance...")
        try:
            test_data = {
                "latitude": 28.6139,
                "longitude": 77.2090,
                "farm_size": 1.0
            }
            
            # Test multiple requests
            times = []
            for i in range(3):
                start_time = time.time()
                response = self.session.post(
                    f"{self.base_url}/ultra-recommend/quick",
                    json=test_data,
                    timeout=60
                )
                end_time = time.time()
                
                if response.status_code == 200:
                    times.append(end_time - start_time)
                else:
                    print(f"❌ Performance test request {i+1} failed: {response.status_code}")
                    return False
            
            avg_time = sum(times) / len(times)
            print(f"✅ Performance test passed")
            print(f"   Average response time: {avg_time:.2f} seconds")
            print(f"   Individual times: {[f'{t:.2f}s' for t in times]}")
            
            if avg_time < 30:
                print("   🚀 Performance: Excellent")
            elif avg_time < 60:
                print("   ✅ Performance: Good")
            else:
                print("   ⚠️  Performance: Slow")
            
            return True
        except Exception as e:
            print(f"❌ Performance test error: {e}")
            return False
    
    def run_all_tests(self) -> Dict[str, bool]:
        """Run all tests and return results"""
        print("=" * 60)
        print("  ULTRA CROP RECOMMENDER - DEPLOYMENT TEST")
        print("=" * 60)
        print(f"Testing service at: {self.base_url}")
        print()
        
        results = {}
        
        # Run all tests
        results['health'] = self.test_health()
        results['quick_recommendation'] = self.test_quick_recommendation()
        results['full_recommendation'] = self.test_full_recommendation()
        results['crop_database'] = self.test_crop_database()
        results['performance'] = self.test_performance()
        
        # Summary
        print("\n" + "=" * 60)
        print("  TEST SUMMARY")
        print("=" * 60)
        
        passed = sum(results.values())
        total = len(results)
        
        for test_name, passed in results.items():
            status = "✅ PASS" if passed else "❌ FAIL"
            print(f"  {test_name.replace('_', ' ').title()}: {status}")
        
        print(f"\nOverall: {passed}/{total} tests passed")
        
        if passed == total:
            print("🎉 All tests passed! Deployment is working correctly.")
        else:
            print("⚠️  Some tests failed. Check the logs and configuration.")
        
        return results

def main():
    """Main function"""
    if len(sys.argv) != 2:
        print("Usage: python test-ultra-crop-deployment.py <SERVICE_URL>")
        print("Example: python test-ultra-crop-deployment.py https://ultra-crop-recommender-api-xxx-uc.a.run.app")
        sys.exit(1)
    
    service_url = sys.argv[1]
    tester = UltraCropTester(service_url)
    results = tester.run_all_tests()
    
    # Exit with appropriate code
    if all(results.values()):
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()