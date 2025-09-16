#!/usr/bin/env python3
"""
Simple System Startup for SIH 2025 Harvest Enterprise
Starts PostgreSQL (if not running) and working APIs
"""

import subprocess
import time
import logging
import os
import sys
import threading
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SimpleSystemManager:
    def __init__(self):
        self.postgresql_data_dir = r"C:\Program Files\PostgreSQL\17\data"
        self.pg_ctl_path = r"C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe"
        self.running_processes = {}
        
    def check_postgresql(self):
        """Check if PostgreSQL is responding"""
        try:
            import psycopg2
            conn = psycopg2.connect(
                host="localhost",
                port=5432,
                user="postgres",
                password="postgres",
                database="postgres"
            )
            conn.close()
            return True
        except Exception:
            return False
    
    def start_postgresql_if_needed(self):
        """Start PostgreSQL if not running"""
        if self.check_postgresql():
            logger.info("✅ PostgreSQL is already running")
            return True
        
        logger.info("🌐 Starting PostgreSQL service...")
        try:
            result = subprocess.run(
                [self.pg_ctl_path, "start", "-D", self.postgresql_data_dir],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                logger.info("✅ PostgreSQL started successfully")
                # Wait for it to be ready
                for attempt in range(10):
                    if self.check_postgresql():
                        logger.info("✅ PostgreSQL is ready")
                        return True
                    time.sleep(2)
                logger.error("❌ PostgreSQL not ready after start")
                return False
            else:
                logger.warning(f"⚠️  PostgreSQL start warning: {result.stderr}")
                # Check if it's actually running despite the warning
                if self.check_postgresql():
                    logger.info("✅ PostgreSQL is running despite warning")
                    return True
                else:
                    logger.error("❌ PostgreSQL not running after start attempt")
                    return False
                
        except Exception as e:
            logger.error(f"❌ Error starting PostgreSQL: {e}")
            return False
    
    def start_api(self, api_name, api_file, port):
        """Start a single API"""
        try:
            logger.info(f"🚀 Starting {api_name} on port {port}...")
            
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
    
    def start_working_apis(self):
        """Start the APIs that are known to work"""
        working_apis = [
            ('Crop Recommendation API', 'src/api/crop_api_production.py', 8080),
            ('Market Price API', 'src/api/market_price_api_fixed.py', 5004),
            ('SIH 2025 Integrated API', 'src/api/sih_2025_integrated_api.py', 5012)
        ]
        
        logger.info("🚀 Starting working APIs...")
        started_count = 0
        
        for api_name, api_file, port in working_apis:
            if self.start_api(api_name, api_file, port):
                started_count += 1
                time.sleep(3)  # Wait between API starts
            else:
                logger.warning(f"⚠️  Failed to start {api_name}")
        
        return started_count
    
    def start_system(self):
        """Start the complete system"""
        logger.info("🌾 SIH 2025 Harvest Enterprise - Simple System Startup")
        logger.info("=" * 60)
        
        # Start PostgreSQL if needed
        if not self.start_postgresql_if_needed():
            logger.error("❌ Cannot start system without PostgreSQL")
            return False
        
        # Start working APIs
        started_count = self.start_working_apis()
        
        if started_count > 0:
            logger.info(f"✅ {started_count} APIs started successfully")
            logger.info("🌐 System is running!")
            logger.info("📱 Frontend can now connect to the backend")
            logger.info("🔄 Press Ctrl+C to stop the system")
            
            try:
                # Keep the main thread alive
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                logger.info("🛑 Shutting down system...")
                for api_name, process in self.running_processes.items():
                    try:
                        process.terminate()
                        logger.info(f"✅ {api_name} stopped")
                    except Exception as e:
                        logger.warning(f"⚠️  Error stopping {api_name}: {e}")
                logger.info("✅ System shutdown complete")
        else:
            logger.error("❌ No APIs started successfully")
            return False
        
        return True

def main():
    """Main function"""
    system_manager = SimpleSystemManager()
    
    try:
        system_manager.start_system()
    except Exception as e:
        logger.error(f"❌ Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
