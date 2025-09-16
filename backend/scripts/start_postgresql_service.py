#!/usr/bin/env python3
"""
Simple PostgreSQL Service Starter
Starts PostgreSQL and keeps it running for SIH 2025 APIs
"""

import subprocess
import time
import logging
import os
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def start_postgresql():
    """Start PostgreSQL service"""
    postgresql_data_dir = r"C:\Program Files\PostgreSQL\17\data"
    pg_ctl_path = r"C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe"
    
    try:
        logger.info("Starting PostgreSQL service...")
        result = subprocess.run(
            [pg_ctl_path, "start", "-D", postgresql_data_dir],
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
            
    except subprocess.TimeoutExpired:
        logger.error("❌ PostgreSQL start command timed out")
        return False
    except Exception as e:
        logger.error(f"❌ Error starting PostgreSQL: {e}")
        return False

def check_postgresql():
    """Check if PostgreSQL is running"""
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

def main():
    """Main function"""
    print("🌐 PostgreSQL Service Starter for SIH 2025 Harvest Enterprise")
    print("=" * 60)
    
    # Check if PostgreSQL is already running
    if check_postgresql():
        print("✅ PostgreSQL is already running and responding")
        print("🔄 Keeping service alive...")
        
        try:
            while True:
                time.sleep(30)
                if not check_postgresql():
                    print("⚠️  PostgreSQL stopped, restarting...")
                    if start_postgresql():
                        print("✅ PostgreSQL restarted successfully")
                    else:
                        print("❌ Failed to restart PostgreSQL")
                        break
        except KeyboardInterrupt:
            print("\n🛑 Service stopped by user")
    else:
        print("🚀 Starting PostgreSQL service...")
        if start_postgresql():
            print("✅ PostgreSQL started successfully")
            print("🔄 Keeping service alive...")
            
            try:
                while True:
                    time.sleep(30)
                    if not check_postgresql():
                        print("⚠️  PostgreSQL stopped, restarting...")
                        if start_postgresql():
                            print("✅ PostgreSQL restarted successfully")
                        else:
                            print("❌ Failed to restart PostgreSQL")
                            break
            except KeyboardInterrupt:
                print("\n🛑 Service stopped by user")
        else:
            print("❌ Failed to start PostgreSQL")
            sys.exit(1)

if __name__ == "__main__":
    main()
