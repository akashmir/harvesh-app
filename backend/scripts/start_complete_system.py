#!/usr/bin/env python3
"""
Complete System Startup for SIH 2025 Harvest Enterprise
Starts PostgreSQL and all APIs in the correct order
"""

import subprocess
import time
import logging
import os
import sys
import threading
import requests
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SystemManager:
    def __init__(self):
        self.postgresql_data_dir = r"C:\Program Files\PostgreSQL\17\data"
        self.pg_ctl_path = r"C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe"
        self.running_processes = {}
        self.api_endpoints = {
            'crop_recommendation': 'http://localhost:8080',
            'weather_integration': 'http://localhost:5005',
            'market_price': 'http://localhost:5004',
            'yield_prediction': 'http://localhost:5003',
            'field_management': 'http://localhost:5002',
            'satellite_soil': 'http://localhost:5006',
            'multilingual_ai': 'http://localhost:5007',
            'disease_detection': 'http://localhost:5008',
            'sustainability': 'http://localhost:5009',
            'crop_rotation': 'http://localhost:5010',
            'offline_capability': 'http://localhost:5011',
            'integrated_api': 'http://localhost:5012'
        }
        
    def start_postgresql(self):
        """Start PostgreSQL service"""
        try:
            logger.info("🌐 Starting PostgreSQL service...")
            result = subprocess.run(
                [self.pg_ctl_path, "start", "-D", self.postgresql_data_dir],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                logger.info("✅ PostgreSQL started successfully")
                return True
            else:
                logger.error(f"❌ Failed to start PostgreSQL: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Error starting PostgreSQL: {e}")
            return False
    
    def check_postgresql(self):
        """Check if PostgreSQL is responding"""
        try:
            import psycopg2
            conn = psycopg2.connect(
                host="localhost",
                port=5432,
                user="postgres",
                password="postgres",  # Update with your password
                database="postgres"
            )
            conn.close()
            return True
        except Exception:
            return False
    
    def wait_for_postgresql(self, max_attempts=20):
        """Wait for PostgreSQL to be ready"""
        logger.info("⏳ Waiting for PostgreSQL to be ready...")
        for attempt in range(max_attempts):
            if self.check_postgresql():
                logger.info("✅ PostgreSQL is ready")
                return True
            logger.info(f"   Attempt {attempt + 1}/{max_attempts}...")
            time.sleep(3)
        
        logger.error("❌ PostgreSQL not ready after maximum attempts")
        return False
    
    def start_api(self, api_name, api_file, port):
        """Start a single API"""
        try:
            logger.info(f"🚀 Starting {api_name} on port {port}...")
            
            # Start the API process
            process = subprocess.Popen(
                [sys.executable, api_file],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            self.running_processes[api_name] = process
            logger.info(f"✅ {api_name} started (PID: {process.pid})")
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to start {api_name}: {e}")
            return False
    
    def check_api_health(self, api_name, endpoint):
        """Check if an API is healthy"""
        try:
            response = requests.get(f"{endpoint}/health", timeout=5)
            if response.status_code == 200:
                return True
        except Exception:
            pass
        return False
    
    def start_working_apis(self):
        """Start the APIs that are known to work"""
        working_apis = [
            ('Crop Recommendation API', 'src/api/crop_api_production.py', 8080),
            ('Weather Integration API', 'src/api/weather_integration_api_simple.py', 5005),
            ('Market Price API', 'src/api/market_price_api_fixed.py', 5004),
            ('SIH 2025 Integrated API', 'src/api/sih_2025_integrated_api.py', 5012)
        ]
        
        logger.info("🚀 Starting working APIs...")
        
        for api_name, api_file, port in working_apis:
            if self.start_api(api_name, api_file, port):
                time.sleep(5)  # Wait between API starts
            else:
                logger.warning(f"⚠️  Failed to start {api_name}")
        
        return len(self.running_processes)
    
    def monitor_apis(self):
        """Monitor API health and restart if needed"""
        logger.info("🔍 Starting API monitoring...")
        
        try:
            while True:
                for api_name, process in self.running_processes.items():
                    if process.poll() is not None:
                        logger.warning(f"⚠️  {api_name} stopped unexpectedly")
                        # Restart logic could be added here
                
                time.sleep(30)  # Check every 30 seconds
                
        except KeyboardInterrupt:
            logger.info("🛑 Monitoring stopped by user")
    
    def stop_all_apis(self):
        """Stop all running APIs"""
        logger.info("🛑 Stopping all APIs...")
        
        for api_name, process in self.running_processes.items():
            try:
                process.terminate()
                process.wait(timeout=10)
                logger.info(f"✅ {api_name} stopped")
            except Exception as e:
                logger.warning(f"⚠️  Error stopping {api_name}: {e}")
        
        self.running_processes.clear()
    
    def start_system(self):
        """Start the complete system"""
        logger.info("🌾 SIH 2025 Harvest Enterprise - Complete System Startup")
        logger.info("=" * 60)
        
        # Start PostgreSQL
        if not self.start_postgresql():
            logger.error("❌ Cannot start system without PostgreSQL")
            return False
        
        # Wait for PostgreSQL to be ready
        if not self.wait_for_postgresql():
            logger.error("❌ PostgreSQL not ready, cannot start APIs")
            return False
        
        # Start working APIs
        started_count = self.start_working_apis()
        
        if started_count > 0:
            logger.info(f"✅ {started_count} APIs started successfully")
            logger.info("🌐 System is running!")
            logger.info("📱 Frontend can now connect to the backend")
            logger.info("🔄 Press Ctrl+C to stop the system")
            
            # Start monitoring in a separate thread
            monitor_thread = threading.Thread(target=self.monitor_apis)
            monitor_thread.daemon = True
            monitor_thread.start()
            
            try:
                # Keep the main thread alive
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                logger.info("🛑 Shutting down system...")
                self.stop_all_apis()
                logger.info("✅ System shutdown complete")
        else:
            logger.error("❌ No APIs started successfully")
            return False
        
        return True

def main():
    """Main function"""
    system_manager = SystemManager()
    
    try:
        system_manager.start_system()
    except Exception as e:
        logger.error(f"❌ Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
