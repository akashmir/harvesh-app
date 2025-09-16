#!/usr/bin/env python3
"""
PostgreSQL Service Manager for SIH 2025 Harvest Enterprise
Keeps PostgreSQL running consistently to prevent API failures
"""

import subprocess
import time
import logging
import psutil
import os
import sys
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('postgresql_service.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class PostgreSQLServiceManager:
    def __init__(self):
        self.postgresql_data_dir = r"C:\Program Files\PostgreSQL\17\data"
        self.postgresql_bin_dir = r"C:\Program Files\PostgreSQL\17\bin"
        self.pg_ctl_path = os.path.join(self.postgresql_bin_dir, "pg_ctl.exe")
        self.check_interval = 30  # Check every 30 seconds
        self.max_restart_attempts = 5
        self.restart_delay = 10  # Wait 10 seconds between restart attempts
        
    def is_postgresql_running(self):
        """Check if PostgreSQL is running by looking for postgres processes"""
        try:
            for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                if proc.info['name'] and 'postgres' in proc.info['name'].lower():
                    return True
            return False
        except Exception as e:
            logger.error(f"Error checking PostgreSQL processes: {e}")
            return False
    
    def is_postgresql_responding(self):
        """Check if PostgreSQL is responding to connections"""
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
        except Exception as e:
            logger.warning(f"PostgreSQL not responding: {e}")
            return False
    
    def start_postgresql(self):
        """Start PostgreSQL service"""
        try:
            logger.info("Starting PostgreSQL service...")
            result = subprocess.run(
                [self.pg_ctl_path, "start", "-D", self.postgresql_data_dir],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                logger.info("PostgreSQL started successfully")
                return True
            else:
                logger.error(f"Failed to start PostgreSQL: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            logger.error("PostgreSQL start command timed out")
            return False
        except Exception as e:
            logger.error(f"Error starting PostgreSQL: {e}")
            return False
    
    def stop_postgresql(self):
        """Stop PostgreSQL service"""
        try:
            logger.info("Stopping PostgreSQL service...")
            result = subprocess.run(
                [self.pg_ctl_path, "stop", "-D", self.postgresql_data_dir],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                logger.info("PostgreSQL stopped successfully")
                return True
            else:
                logger.warning(f"PostgreSQL stop warning: {result.stderr}")
                return True  # Still consider it successful
                
        except subprocess.TimeoutExpired:
            logger.warning("PostgreSQL stop command timed out")
            return True
        except Exception as e:
            logger.error(f"Error stopping PostgreSQL: {e}")
            return False
    
    def restart_postgresql(self):
        """Restart PostgreSQL service"""
        logger.info("Restarting PostgreSQL service...")
        self.stop_postgresql()
        time.sleep(5)  # Wait for complete shutdown
        return self.start_postgresql()
    
    def ensure_postgresql_running(self):
        """Ensure PostgreSQL is running and responding"""
        if not self.is_postgresql_running():
            logger.warning("PostgreSQL is not running, attempting to start...")
            if not self.start_postgresql():
                logger.error("Failed to start PostgreSQL")
                return False
        
        # Wait for PostgreSQL to be ready
        for attempt in range(10):
            if self.is_postgresql_responding():
                logger.info("PostgreSQL is running and responding")
                return True
            logger.info(f"Waiting for PostgreSQL to be ready... (attempt {attempt + 1}/10)")
            time.sleep(3)
        
        logger.error("PostgreSQL is not responding after multiple attempts")
        return False
    
    def monitor_and_maintain(self):
        """Main monitoring loop"""
        logger.info("PostgreSQL Service Manager started")
        logger.info(f"Monitoring PostgreSQL every {self.check_interval} seconds")
        logger.info("Press Ctrl+C to stop")
        
        consecutive_failures = 0
        
        try:
            while True:
                try:
                    if not self.is_postgresql_responding():
                        logger.warning("PostgreSQL is not responding, attempting restart...")
                        consecutive_failures += 1
                        
                        if consecutive_failures <= self.max_restart_attempts:
                            if self.restart_postgresql():
                                consecutive_failures = 0
                                logger.info("PostgreSQL restarted successfully")
                            else:
                                logger.error(f"Failed to restart PostgreSQL (attempt {consecutive_failures})")
                                time.sleep(self.restart_delay)
                        else:
                            logger.error(f"Max restart attempts ({self.max_restart_attempts}) reached")
                            logger.error("PostgreSQL service manager stopping")
                            break
                    else:
                        consecutive_failures = 0
                        logger.debug("PostgreSQL is running normally")
                    
                    time.sleep(self.check_interval)
                    
                except KeyboardInterrupt:
                    logger.info("Received interrupt signal, stopping...")
                    break
                except Exception as e:
                    logger.error(f"Unexpected error in monitoring loop: {e}")
                    time.sleep(self.check_interval)
                    
        except Exception as e:
            logger.error(f"Fatal error in service manager: {e}")
        finally:
            logger.info("PostgreSQL Service Manager stopped")

def main():
    """Main function"""
    print("🌐 PostgreSQL Service Manager for SIH 2025 Harvest Enterprise")
    print("=" * 60)
    
    # Check if running as administrator
    try:
        is_admin = os.getuid() == 0
    except AttributeError:
        is_admin = False
    
    if not is_admin:
        print("⚠️  Warning: Not running as administrator")
        print("   Some operations may require elevated privileges")
    
    # Check if PostgreSQL is installed
    manager = PostgreSQLServiceManager()
    
    if not os.path.exists(manager.pg_ctl_path):
        print(f"❌ PostgreSQL not found at: {manager.pg_ctl_path}")
        print("   Please install PostgreSQL or update the path")
        sys.exit(1)
    
    if not os.path.exists(manager.postgresql_data_dir):
        print(f"❌ PostgreSQL data directory not found: {manager.postgresql_data_dir}")
        print("   Please initialize PostgreSQL database")
        sys.exit(1)
    
    print("✅ PostgreSQL installation found")
    
    # Initial check and start
    if not manager.ensure_postgresql_running():
        print("❌ Failed to start PostgreSQL")
        sys.exit(1)
    
    print("✅ PostgreSQL is running and ready")
    print("🔄 Starting monitoring loop...")
    
    # Start monitoring
    manager.monitor_and_maintain()

if __name__ == "__main__":
    main()
