"""
SIH 2025 Harvest Enterprise - PostgreSQL Startup Script
Starts all APIs with PostgreSQL database backend
"""

import os
import sys
import subprocess
import time
import signal
import threading
from datetime import datetime

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.database import health_check

class APIManager:
    def __init__(self):
        self.processes = []
        self.running = True
        
        # API configurations with PostgreSQL support
        self.apis = [
            {
                'name': 'Crop Recommendation API',
                'file': 'crop_api_postgresql.py',
                'port': 8080,
                'description': 'ML-based crop recommendations with PostgreSQL'
            },
            {
                'name': 'Weather Integration API',
                'file': 'weather_integration_api.py',
                'port': 5005,
                'description': 'Real-time weather data and forecasts'
            },
            {
                'name': 'Market Price API',
                'file': 'market_price_api.py',
                'port': 5004,
                'description': 'Market prices and profit calculations'
            },
            {
                'name': 'Yield Prediction API',
                'file': 'yield_prediction_api.py',
                'port': 5003,
                'description': 'ML-based yield forecasting'
            },
            {
                'name': 'Field Management API',
                'file': 'field_management_api.py',
                'port': 5002,
                'description': 'Field tracking and crop scheduling'
            },
            {
                'name': 'Satellite Soil API',
                'file': 'satellite_soil_api.py',
                'port': 5006,
                'description': 'Satellite imagery and soil analysis'
            },
            {
                'name': 'Multilingual AI API',
                'file': 'multilingual_ai_api.py',
                'port': 5007,
                'description': 'Multi-language support and translations'
            },
            {
                'name': 'Disease Detection API',
                'file': 'ai_disease_detection_api.py',
                'port': 5008,
                'description': 'AI-powered plant disease detection'
            },
            {
                'name': 'Sustainability Scoring API',
                'file': 'sustainability_scoring_api.py',
                'port': 5009,
                'description': 'Environmental impact assessment'
            },
            {
                'name': 'Crop Rotation API',
                'file': 'crop_rotation_api.py',
                'port': 5010,
                'description': 'Crop rotation planning and optimization'
            },
            {
                'name': 'Offline Capability API',
                'file': 'offline_capability_api.py',
                'port': 5011,
                'description': 'Offline data synchronization'
            },
            {
                'name': 'Integrated SIH 2025 API',
                'file': 'sih_2025_integrated_api.py',
                'port': 5012,
                'description': 'Main integrated API endpoint'
            }
        ]
    
    def check_database_health(self):
        """Check if PostgreSQL database is healthy"""
        print("🔍 Checking database health...")
        if health_check():
            print("✅ Database is healthy and ready")
            return True
        else:
            print("❌ Database health check failed")
            print("💡 Run: python scripts/setup_database.py")
            return False
    
    def start_api(self, api_config):
        """Start a single API"""
        try:
            print(f"🚀 Starting {api_config['name']} on port {api_config['port']}...")
            
            # Start the API process
            process = subprocess.Popen([
                sys.executable, api_config['file']
            ], cwd=os.path.join(os.path.dirname(__file__), '..'))
            
            self.processes.append({
                'process': process,
                'config': api_config,
                'started_at': datetime.now()
            })
            
            print(f"✅ {api_config['name']} started successfully")
            return True
            
        except Exception as e:
            print(f"❌ Failed to start {api_config['name']}: {e}")
            return False
    
    def wait_for_api_health(self, api_config, timeout=30):
        """Wait for API to become healthy"""
        import requests
        
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                response = requests.get(f"http://localhost:{api_config['port']}/health", timeout=5)
                if response.status_code == 200:
                    print(f"✅ {api_config['name']} is healthy and ready")
                    return True
            except:
                pass
            
            time.sleep(2)
        
        print(f"⚠️ {api_config['name']} may not be ready after {timeout} seconds")
        return False
    
    def start_all_apis(self):
        """Start all APIs"""
        print("🌾 SIH 2025 AI-Based Crop Recommendation System")
        print("=" * 60)
        print(f"🕐 Starting at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Check database first
        if not self.check_database_health():
            return False
        
        print()
        
        # Start APIs one by one
        for api_config in self.apis:
            if self.start_api(api_config):
                # Wait for API to be ready
                self.wait_for_api_health(api_config)
            else:
                print(f"⚠️ Skipping {api_config['name']} due to startup failure")
            
            time.sleep(1)  # Small delay between API starts
        
        print()
        print("🎉 All APIs started successfully!")
        print("=" * 60)
        print("📱 Available APIs:")
        for api_config in self.apis:
            print(f"  • {api_config['name']} - http://localhost:{api_config['port']}")
        
        print()
        print("🔗 Main Integrated API: http://localhost:5012")
        print("📊 Health Check: http://localhost:5012/health")
        print()
        print("📱 Flutter App Integration:")
        print("  • Update API base URL to: http://10.0.2.2:5012")
        print("  • For Android emulator access")
        print()
        print("🛑 Press Ctrl+C to stop all services")
        
        return True
    
    def monitor_processes(self):
        """Monitor running processes"""
        while self.running:
            for api_info in self.processes[:]:
                process = api_info['process']
                if process.poll() is not None:
                    print(f"⚠️ {api_info['config']['name']} has stopped unexpectedly")
                    self.processes.remove(api_info)
            
            time.sleep(5)
    
    def stop_all_apis(self):
        """Stop all running APIs"""
        print("\n🛑 Stopping all APIs...")
        self.running = False
        
        for api_info in self.processes:
            try:
                process = api_info['process']
                if process.poll() is None:  # Process is still running
                    process.terminate()
                    process.wait(timeout=5)
                    print(f"✅ {api_info['config']['name']} stopped")
            except:
                try:
                    process.kill()
                    print(f"✅ {api_info['config']['name']} force stopped")
                except:
                    print(f"⚠️ Could not stop {api_info['config']['name']}")
        
        print("👋 All APIs stopped. Goodbye!")
    
    def run(self):
        """Main run method"""
        try:
            if self.start_all_apis():
                # Start monitoring in a separate thread
                monitor_thread = threading.Thread(target=self.monitor_processes)
                monitor_thread.daemon = True
                monitor_thread.start()
                
                # Keep main thread alive
                while self.running:
                    time.sleep(1)
        
        except KeyboardInterrupt:
            print("\n🛑 Received interrupt signal...")
        finally:
            self.stop_all_apis()

def main():
    """Main function"""
    # Check if we're in the right directory
    if not os.path.exists('src/api/integrated_api.py'):
        print("❌ Error: Please run this script from the backend directory")
        print("Current directory:", os.getcwd())
        print("Expected files: src/api/integrated_api.py")
        sys.exit(1)
    
    # Create and run API manager
    manager = APIManager()
    manager.run()

if __name__ == "__main__":
    main()

