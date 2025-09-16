#!/usr/bin/env python3
"""
Complete SIH 2025 Integration Test
Tests the entire system including Flutter app integration
"""

import requests
import json
import time
from datetime import datetime

class CompleteIntegrationTester:
    def __init__(self):
        self.base_urls = {
            'crop': 'http://localhost:8080',
            'weather': 'http://localhost:5005',
            'market': 'http://localhost:5004',
            'soil': 'http://localhost:5006',
            'multilingual': 'http://localhost:5007',
            'disease': 'http://localhost:5008',
            'sustainability': 'http://localhost:5009',
            'rotation': 'http://localhost:5010',
            'offline': 'http://localhost:5011',
            'integrated': 'http://localhost:5012'
        }
        self.test_results = []

    def test_api_health(self, api_name, base_url):
        """Test individual API health"""
        try:
            response = requests.get(f"{base_url}/health", timeout=5)
            if response.status_code == 200:
                data = response.json()
                return {
                    'api': api_name,
                    'status': 'healthy',
                    'response_time': response.elapsed.total_seconds(),
                    'message': data.get('message', 'OK')
                }
            else:
                return {
                    'api': api_name,
                    'status': 'unhealthy',
                    'response_time': response.elapsed.total_seconds(),
                    'error': f"HTTP {response.status_code}"
                }
        except Exception as e:
            return {
                'api': api_name,
                'status': 'error',
                'response_time': 0,
                'error': str(e)
            }

    def test_crop_recommendation(self):
        """Test crop recommendation functionality"""
        print("🌾 Testing Crop Recommendation...")
        
        test_data = {
            'N': 50.0,
            'P': 30.0,
            'K': 40.0,
            'temperature': 25.0,
            'humidity': 70.0,
            'ph': 7.0,
            'rainfall': 100.0,
            'model': 'random_forest'
        }
        
        try:
            response = requests.post(
                f"{self.base_urls['crop']}/recommend",
                json=test_data,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                return {
                    'test': 'crop_recommendation',
                    'status': 'pass',
                    'recommendation': data.get('recommendation', 'Unknown'),
                    'confidence': data.get('confidence', 0),
                    'response_time': response.elapsed.total_seconds()
                }
            else:
                return {
                    'test': 'crop_recommendation',
                    'status': 'fail',
                    'error': f"HTTP {response.status_code}",
                    'response_time': response.elapsed.total_seconds()
                }
        except Exception as e:
            return {
                'test': 'crop_recommendation',
                'status': 'error',
                'error': str(e),
                'response_time': 0
            }

    def test_weather_integration(self):
        """Test weather integration"""
        print("🌤️ Testing Weather Integration...")
        
        try:
            response = requests.get(
                f"{self.base_urls['weather']}/weather/current",
                params={'lat': 28.6139, 'lon': 77.209, 'location': 'Delhi'},
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                return {
                    'test': 'weather_integration',
                    'status': 'pass',
                    'temperature': data.get('data', {}).get('temperature', 'Unknown'),
                    'humidity': data.get('data', {}).get('humidity', 'Unknown'),
                    'response_time': response.elapsed.total_seconds()
                }
            else:
                return {
                    'test': 'weather_integration',
                    'status': 'fail',
                    'error': f"HTTP {response.status_code}",
                    'response_time': response.elapsed.total_seconds()
                }
        except Exception as e:
            return {
                'test': 'weather_integration',
                'status': 'error',
                'error': str(e),
                'response_time': 0
            }

    def test_satellite_soil_data(self):
        """Test satellite soil data"""
        print("🛰️ Testing Satellite Soil Data...")
        
        try:
            response = requests.get(
                f"{self.base_urls['soil']}/soil/current",
                params={'lat': 28.6139, 'lon': 77.209, 'location': 'Delhi'},
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                soil_data = data.get('data', {})
                return {
                    'test': 'satellite_soil_data',
                    'status': 'pass',
                    'ph': soil_data.get('soil_properties', {}).get('ph', 'Unknown'),
                    'health_score': soil_data.get('health_indicators', {}).get('health_score', 'Unknown'),
                    'response_time': response.elapsed.total_seconds()
                }
            else:
                return {
                    'test': 'satellite_soil_data',
                    'status': 'fail',
                    'error': f"HTTP {response.status_code}",
                    'response_time': response.elapsed.total_seconds()
                }
        except Exception as e:
            return {
                'test': 'satellite_soil_data',
                'status': 'error',
                'error': str(e),
                'response_time': 0
            }

    def test_multilingual_chat(self):
        """Test multilingual chat"""
        print("🗣️ Testing Multilingual Chat...")
        
        test_messages = [
            {'message': 'What crops should I plant?', 'language': 'en'},
            {'message': 'मुझे कौन सी फसलें लगानी चाहिए?', 'language': 'hi'},
            {'message': 'আমার কি ফসল লাগানো উচিত?', 'language': 'bn'}
        ]
        
        results = []
        for msg in test_messages:
            try:
                response = requests.post(
                    f"{self.base_urls['multilingual']}/chat",
                    json=msg,
                    timeout=10
                )
                
                if response.status_code == 200:
                    data = response.json()
                    results.append({
                        'language': msg['language'],
                        'status': 'pass',
                        'response': data.get('response', 'No response')[:50] + '...',
                        'response_time': response.elapsed.total_seconds()
                    })
                else:
                    results.append({
                        'language': msg['language'],
                        'status': 'fail',
                        'error': f"HTTP {response.status_code}",
                        'response_time': response.elapsed.total_seconds()
                    })
            except Exception as e:
                results.append({
                    'language': msg['language'],
                    'status': 'error',
                    'error': str(e),
                    'response_time': 0
                })
        
        return {
            'test': 'multilingual_chat',
            'status': 'pass' if all(r['status'] == 'pass' for r in results) else 'fail',
            'results': results
        }

    def test_disease_detection(self):
        """Test disease detection"""
        print("🔬 Testing Disease Detection...")
        
        try:
            # Test with a sample image (base64 encoded)
            test_data = {
                'image_data': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
                'crop_type': 'rice',
                'language': 'en'
            }
            
            response = requests.post(
                f"{self.base_urls['disease']}/detect/analyze",
                json=test_data,
                timeout=15
            )
            
            if response.status_code == 200:
                data = response.json()
                return {
                    'test': 'disease_detection',
                    'status': 'pass',
                    'detection': data.get('detection', 'Unknown'),
                    'confidence': data.get('confidence', 0),
                    'response_time': response.elapsed.total_seconds()
                }
            else:
                return {
                    'test': 'disease_detection',
                    'status': 'fail',
                    'error': f"HTTP {response.status_code}",
                    'response_time': response.elapsed.total_seconds()
                }
        except Exception as e:
            return {
                'test': 'disease_detection',
                'status': 'error',
                'error': str(e),
                'response_time': 0
            }

    def test_sustainability_scoring(self):
        """Test sustainability scoring"""
        print("🌱 Testing Sustainability Scoring...")
        
        test_data = {
            'user_id': 'test_user',
            'crop_data': {
                'crop_type': 'rice',
                'variety': 'basmati',
                'season': 'kharif'
            },
            'farm_conditions': {
                'farm_area': 5.0,
                'irrigation_type': 'drip',
                'fertilizer_usage': 'organic',
                'pesticide_usage': 'minimal',
                'location': 'Delhi'
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_urls['sustainability']}/assess/sustainability",
                json=test_data,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                return {
                    'test': 'sustainability_scoring',
                    'status': 'pass',
                    'score': data.get('data', {}).get('sustainability_score', 'Unknown'),
                    'carbon_footprint': data.get('data', {}).get('carbon_footprint', 'Unknown'),
                    'response_time': response.elapsed.total_seconds()
                }
            else:
                return {
                    'test': 'sustainability_scoring',
                    'status': 'fail',
                    'error': f"HTTP {response.status_code}",
                    'response_time': response.elapsed.total_seconds()
                }
        except Exception as e:
            return {
                'test': 'sustainability_scoring',
                'status': 'error',
                'error': str(e),
                'response_time': 0
            }

    def test_comprehensive_recommendation(self):
        """Test comprehensive SIH 2025 recommendation"""
        print("🎯 Testing Comprehensive SIH 2025 Recommendation...")
        
        test_data = {
            'soil_data': {
                'ph': 7.0,
                'nitrogen': 50.0,
                'phosphorus': 30.0,
                'potassium': 40.0,
                'moisture': 60.0
            },
            'weather_data': {
                'temperature': 25.0,
                'humidity': 70.0,
                'rainfall': 100.0,
                'wind_speed': 5.0
            },
            'location_data': {
                'latitude': 28.6139,
                'longitude': 77.2090,
                'location': 'Delhi'
            },
            'language': 'en',
            'include_sustainability': True,
            'include_market_analysis': True
        }
        
        try:
            response = requests.post(
                f"{self.base_urls['integrated']}/comprehensive",
                json=test_data,
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                return {
                    'test': 'comprehensive_recommendation',
                    'status': 'pass',
                    'recommendation': data.get('recommendation', 'Unknown'),
                    'confidence': data.get('confidence', 0),
                    'sustainability': data.get('sustainability', 'Unknown'),
                    'market_outlook': data.get('market_outlook', 'Unknown'),
                    'response_time': response.elapsed.total_seconds()
                }
            else:
                return {
                    'test': 'comprehensive_recommendation',
                    'status': 'fail',
                    'error': f"HTTP {response.status_code}",
                    'response_time': response.elapsed.total_seconds()
                }
        except Exception as e:
            return {
                'test': 'comprehensive_recommendation',
                'status': 'error',
                'error': str(e),
                'response_time': 0
            }

    def run_complete_test(self):
        """Run complete integration test"""
        print("🧪 SIH 2025 Complete Integration Test")
        print("=" * 60)
        print(f"🕐 Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Test API Health
        print("🔍 Testing API Health...")
        health_results = []
        for api_name, base_url in self.base_urls.items():
            result = self.test_api_health(api_name, base_url)
            health_results.append(result)
            status_icon = "✅" if result['status'] == 'healthy' else "❌"
            print(f"  {status_icon} {api_name}: {result['status']} ({result['response_time']:.2f}s)")
        
        print()
        
        # Test Core Functionality
        functionality_tests = [
            self.test_crop_recommendation,
            self.test_weather_integration,
            self.test_satellite_soil_data,
            self.test_multilingual_chat,
            self.test_disease_detection,
            self.test_sustainability_scoring,
            self.test_comprehensive_recommendation
        ]
        
        functionality_results = []
        for test_func in functionality_tests:
            result = test_func()
            functionality_results.append(result)
            status_icon = "✅" if result['status'] == 'pass' else "❌"
            print(f"  {status_icon} {result['test']}: {result['status']}")
            if result.get('response_time'):
                print(f"      Response time: {result['response_time']:.2f}s")
            print()
        
        # Summary
        healthy_apis = sum(1 for r in health_results if r['status'] == 'healthy')
        passed_tests = sum(1 for r in functionality_results if r['status'] == 'pass')
        
        print("=" * 60)
        print("📊 TEST SUMMARY")
        print("=" * 60)
        print(f"✅ Healthy APIs: {healthy_apis}/{len(health_results)}")
        print(f"✅ Passed Tests: {passed_tests}/{len(functionality_tests)}")
        print(f"🎯 Overall Success Rate: {(healthy_apis + passed_tests) / (len(health_results) + len(functionality_tests)) * 100:.1f}%")
        
        if healthy_apis == len(health_results) and passed_tests == len(functionality_tests):
            print("🎉 ALL TESTS PASSED! SIH 2025 system is fully operational!")
        else:
            print("⚠️ Some tests failed. Please check the system configuration.")
        
        print("=" * 60)
        
        # Save detailed results
        results = {
            'timestamp': datetime.now().isoformat(),
            'health_results': health_results,
            'functionality_results': functionality_results,
            'summary': {
                'healthy_apis': healthy_apis,
                'total_apis': len(health_results),
                'passed_tests': passed_tests,
                'total_tests': len(functionality_tests),
                'success_rate': (healthy_apis + passed_tests) / (len(health_results) + len(functionality_tests)) * 100
            }
        }
        
        with open('complete_integration_test_results.json', 'w') as f:
            json.dump(results, f, indent=2)
        
        print("📄 Detailed results saved to: complete_integration_test_results.json")
        
        return results

def main():
    """Main test function"""
    tester = CompleteIntegrationTester()
    results = tester.run_complete_test()
    
    # Return exit code based on results
    if results['summary']['success_rate'] == 100:
        exit(0)  # Success
    else:
        exit(1)  # Failure

if __name__ == "__main__":
    main()
