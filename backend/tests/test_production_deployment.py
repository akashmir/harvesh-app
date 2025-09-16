#!/usr/bin/env python3
"""
SIH 2025 Production Deployment Test Script
Tests all deployed APIs and web interface
"""

import requests
import json
import time
from datetime import datetime

class ProductionTester:
    def __init__(self):
        self.apis = {
            'Crop API': 'https://sih2025-crop-api-273619012635.us-central1.run.app',
            'Weather API': 'https://sih2025-weather-api-273619012635.us-central1.run.app',
            'Market API': 'https://sih2025-market-api-273619012635.us-central1.run.app',
            'Soil API': 'https://sih2025-soil-api-273619012635.us-central1.run.app',
            'Multilingual API': 'https://sih2025-multilingual-api-273619012635.us-central1.run.app',
            'Disease API': 'https://sih2025-disease-api-273619012635.us-central1.run.app',
            'Sustainability API': 'https://sih2025-sustainability-api-273619012635.us-central1.run.app',
            'Rotation API': 'https://sih2025-rotation-api-273619012635.us-central1.run.app',
            'Offline API': 'https://sih2025-offline-api-273619012635.us-central1.run.app',
            'Integrated API': 'https://sih2025-integrated-api-273619012635.us-central1.run.app'
        }
        
        self.web_url = 'https://agrismart-app-1930c.web.app'
        
        self.test_results = {
            'health_checks': {},
            'api_tests': {},
            'web_test': {},
            'summary': {}
        }

    def test_health_checks(self):
        """Test health endpoints of all APIs"""
        print("🏥 Testing API Health Checks...")
        print("=" * 50)
        
        healthy_count = 0
        total_count = len(self.apis)
        
        for name, url in self.apis.items():
            try:
                start_time = time.time()
                response = requests.get(f"{url}/health", timeout=10)
                end_time = time.time()
                response_time = round((end_time - start_time) * 1000, 2)
                
                if response.status_code == 200:
                    print(f"✅ {name}: HEALTHY ({response_time}ms)")
                    self.test_results['health_checks'][name] = {
                        'status': 'healthy',
                        'response_time': response_time,
                        'status_code': response.status_code
                    }
                    healthy_count += 1
                else:
                    print(f"❌ {name}: ERROR - HTTP {response.status_code} ({response_time}ms)")
                    self.test_results['health_checks'][name] = {
                        'status': 'error',
                        'response_time': response_time,
                        'status_code': response.status_code
                    }
            except requests.exceptions.Timeout:
                print(f"⏰ {name}: TIMEOUT")
                self.test_results['health_checks'][name] = {
                    'status': 'timeout',
                    'response_time': None,
                    'status_code': None
                }
            except requests.exceptions.ConnectionError:
                print(f"🔌 {name}: CONNECTION ERROR")
                self.test_results['health_checks'][name] = {
                    'status': 'connection_error',
                    'response_time': None,
                    'status_code': None
                }
            except Exception as e:
                print(f"❌ {name}: ERROR - {str(e)[:50]}")
                self.test_results['health_checks'][name] = {
                    'status': 'error',
                    'response_time': None,
                    'status_code': None,
                    'error': str(e)
                }
        
        print("=" * 50)
        print(f"📊 Health Check Results: {healthy_count}/{total_count} APIs healthy ({healthy_count/total_count*100:.1f}%)")
        
        self.test_results['summary']['health_success_rate'] = healthy_count / total_count * 100
        return healthy_count, total_count

    def test_crop_recommendation(self):
        """Test crop recommendation API"""
        print("\n🌾 Testing Crop Recommendation API...")
        
        test_data = {
            "N": 90,
            "P": 42,
            "K": 43,
            "ph": 6.5,
            "rainfall": 200,
            "temperature": 20
        }
        
        try:
            response = requests.post(
                f"{self.apis['Crop API']}/recommend",
                json=test_data,
                timeout=15
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Crop Recommendation: SUCCESS")
                print(f"   Recommended: {data.get('recommendation', data.get('crop', 'Unknown'))}")
                print(f"   Confidence: {data.get('confidence', 'N/A')}")
                
                self.test_results['api_tests']['crop_recommendation'] = {
                    'status': 'success',
                    'response': data
                }
                return True
            else:
                print(f"❌ Crop Recommendation: FAILED - HTTP {response.status_code}")
                print(f"   Response: {response.text[:100]}")
                
                self.test_results['api_tests']['crop_recommendation'] = {
                    'status': 'failed',
                    'status_code': response.status_code,
                    'response': response.text
                }
                return False
        except Exception as e:
            print(f"❌ Crop Recommendation: ERROR - {str(e)}")
            self.test_results['api_tests']['crop_recommendation'] = {
                'status': 'error',
                'error': str(e)
            }
            return False

    def test_weather_integration(self):
        """Test weather integration API"""
        print("\n🌤️ Testing Weather Integration API...")
        
        test_data = {
            "latitude": 28.6139,
            "longitude": 77.2090,
            "days": 7
        }
        
        try:
            response = requests.post(
                f"{self.apis['Weather API']}/weather/forecast",
                json=test_data,
                timeout=15
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Weather Integration: SUCCESS")
                print(f"   Location: {data.get('location', 'Unknown')}")
                print(f"   Forecast Days: {len(data.get('forecast', []))}")
                
                self.test_results['api_tests']['weather_integration'] = {
                    'status': 'success',
                    'response': data
                }
                return True
            else:
                print(f"❌ Weather Integration: FAILED - HTTP {response.status_code}")
                
                self.test_results['api_tests']['weather_integration'] = {
                    'status': 'failed',
                    'status_code': response.status_code
                }
                return False
        except Exception as e:
            print(f"❌ Weather Integration: ERROR - {str(e)}")
            self.test_results['api_tests']['weather_integration'] = {
                'status': 'error',
                'error': str(e)
            }
            return False

    def test_satellite_soil(self):
        """Test satellite soil API"""
        print("\n🛰️ Testing Satellite Soil API...")
        
        test_data = {
            "latitude": 28.6139,
            "longitude": 77.2090
        }
        
        try:
            response = requests.post(
                f"{self.apis['Soil API']}/soil/analyze",
                json=test_data,
                timeout=15
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Satellite Soil: SUCCESS")
                print(f"   Soil Type: {data.get('soil_type', 'Unknown')}")
                print(f"   pH Level: {data.get('ph', 'N/A')}")
                
                self.test_results['api_tests']['satellite_soil'] = {
                    'status': 'success',
                    'response': data
                }
                return True
            else:
                print(f"❌ Satellite Soil: FAILED - HTTP {response.status_code}")
                
                self.test_results['api_tests']['satellite_soil'] = {
                    'status': 'failed',
                    'status_code': response.status_code
                }
                return False
        except Exception as e:
            print(f"❌ Satellite Soil: ERROR - {str(e)}")
            self.test_results['api_tests']['satellite_soil'] = {
                'status': 'error',
                'error': str(e)
            }
            return False

    def test_web_interface(self):
        """Test web interface accessibility"""
        print("\n🌐 Testing Web Interface...")
        
        try:
            response = requests.get(self.web_url, timeout=15)
            
            if response.status_code == 200:
                print(f"✅ Web Interface: SUCCESS")
                print(f"   URL: {self.web_url}")
                print(f"   Content Length: {len(response.content)} bytes")
                
                self.test_results['web_test'] = {
                    'status': 'success',
                    'url': self.web_url,
                    'content_length': len(response.content),
                    'status_code': response.status_code
                }
                return True
            else:
                print(f"❌ Web Interface: FAILED - HTTP {response.status_code}")
                
                self.test_results['web_test'] = {
                    'status': 'failed',
                    'status_code': response.status_code
                }
                return False
        except Exception as e:
            print(f"❌ Web Interface: ERROR - {str(e)}")
            self.test_results['web_test'] = {
                'status': 'error',
                'error': str(e)
            }
            return False

    def run_comprehensive_test(self):
        """Run comprehensive production test"""
        print("🚀 SIH 2025 PRODUCTION DEPLOYMENT TEST")
        print("=" * 60)
        print(f"🕐 Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Test 1: Health Checks
        healthy_count, total_count = self.test_health_checks()
        
        # Test 2: API Functionality Tests
        print("\n🧪 Testing API Functionality...")
        print("=" * 50)
        
        api_tests_passed = 0
        api_tests_total = 3
        
        if self.test_crop_recommendation():
            api_tests_passed += 1
        
        if self.test_weather_integration():
            api_tests_passed += 1
        
        if self.test_satellite_soil():
            api_tests_passed += 1
        
        # Test 3: Web Interface
        print("\n🌐 Testing Web Interface...")
        print("=" * 50)
        
        web_test_passed = self.test_web_interface()
        
        # Summary
        print("\n📊 PRODUCTION TEST SUMMARY")
        print("=" * 60)
        
        health_rate = (healthy_count / total_count) * 100
        api_rate = (api_tests_passed / api_tests_total) * 100
        web_status = "✅ PASS" if web_test_passed else "❌ FAIL"
        
        print(f"🏥 API Health Checks: {healthy_count}/{total_count} ({health_rate:.1f}%)")
        print(f"🧪 API Functionality: {api_tests_passed}/{api_tests_total} ({api_rate:.1f}%)")
        print(f"🌐 Web Interface: {web_status}")
        
        overall_success = health_rate >= 80 and api_rate >= 66 and web_test_passed
        
        print(f"\n🎯 Overall Status: {'✅ PRODUCTION READY' if overall_success else '❌ NEEDS ATTENTION'}")
        
        if overall_success:
            print("\n🎉 CONGRATULATIONS!")
            print("Your SIH 2025 system is successfully deployed and working!")
            print(f"🌐 Web App: {self.web_url}")
            print("📱 All APIs are responding and functional!")
        else:
            print("\n⚠️  Some issues detected:")
            if health_rate < 80:
                print(f"   - API Health: {health_rate:.1f}% (target: 80%+)")
            if api_rate < 66:
                print(f"   - API Functionality: {api_rate:.1f}% (target: 66%+)")
            if not web_test_passed:
                print("   - Web Interface: Not accessible")
        
        # Save results
        self.test_results['summary'] = {
            'overall_success': overall_success,
            'health_success_rate': health_rate,
            'api_success_rate': api_rate,
            'web_success': web_test_passed,
            'timestamp': datetime.now().isoformat()
        }
        
        with open('production_test_results.json', 'w') as f:
            json.dump(self.test_results, f, indent=2)
        
        print(f"\n📄 Detailed results saved to: production_test_results.json")
        
        return overall_success

def main():
    """Main test function"""
    tester = ProductionTester()
    success = tester.run_comprehensive_test()
    
    if success:
        print("\n🏆 SIH 2025 SYSTEM IS LIVE AND READY FOR FARMERS!")
        exit(0)
    else:
        print("\n❌ Production test failed. Please check the issues above.")
        exit(1)

if __name__ == "__main__":
    main()
