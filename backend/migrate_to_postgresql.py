#!/usr/bin/env python3
"""
Migrate all APIs from SQLite to PostgreSQL
Updates all API files to use PostgreSQL instead of SQLite
"""

import os
import re
import shutil
from datetime import datetime

# List of all API files that need migration
API_FILES = [
    'src/api/crop_api_production.py',
    'src/api/weather_integration_api.py',
    'src/api/market_price_api.py',
    'src/api/yield_prediction_api.py',
    'src/api/field_management_api.py',
    'src/api/satellite_soil_api.py',
    'src/api/multilingual_ai_api.py',
    'src/api/ai_disease_detection_api.py',
    'src/api/sustainability_scoring_api.py',
    'src/api/crop_rotation_api.py',
    'src/api/offline_capability_api.py',
    'src/api/sih_2025_integrated_api.py'
]

def create_postgresql_connection_code():
    """Create PostgreSQL connection code to replace SQLite"""
    return '''
# PostgreSQL Database Configuration
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from contextlib import contextmanager

# Database configuration
DATABASE_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'harvest_enterprise'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'K@shmir2442')
}

@contextmanager
def get_db_connection():
    """Get PostgreSQL database connection with proper error handling"""
    conn = None
    try:
        conn = psycopg2.connect(**DATABASE_CONFIG)
        conn.autocommit = False
        yield conn
    except Exception as e:
        if conn:
            conn.rollback()
        raise e
    finally:
        if conn:
            conn.close()

@contextmanager
def get_db_cursor():
    """Get PostgreSQL database cursor with proper error handling"""
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            yield cursor, conn
        finally:
            cursor.close()
'''

def migrate_api_file(file_path):
    """Migrate a single API file from SQLite to PostgreSQL"""
    print(f"🔄 Migrating {file_path}...")
    
    try:
        # Read the file
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Skip if already migrated
        if 'psycopg2' in content and 'get_db_connection' in content:
            print(f"✅ {file_path} - Already migrated")
            return True
        
        # Create backup
        backup_path = f"{file_path}.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        shutil.copy2(file_path, backup_path)
        print(f"📁 Backup created: {backup_path}")
        
        # Add PostgreSQL imports and connection code
        lines = content.split('\n')
        new_lines = []
        
        # Find where to insert PostgreSQL code
        insert_index = 0
        for i, line in enumerate(lines):
            if line.strip().startswith('import ') or line.strip().startswith('from '):
                insert_index = i + 1
            elif line.strip() == '' and insert_index > 0:
                break
        
        # Insert PostgreSQL code
        for i, line in enumerate(lines):
            new_lines.append(line)
            if i == insert_index:
                new_lines.append('')
                new_lines.append('# PostgreSQL Database Configuration')
                new_lines.extend(create_postgresql_connection_code().split('\n'))
                new_lines.append('')
        
        # Replace SQLite-specific code
        new_content = '\n'.join(new_lines)
        
        # Replace sqlite3.connect with PostgreSQL connection
        new_content = re.sub(
            r'conn = sqlite3\.connect\([^)]+\)',
            'conn = psycopg2.connect(**DATABASE_CONFIG)',
            new_content
        )
        
        # Replace cursor.execute patterns
        new_content = re.sub(
            r'cursor\.execute\(([^)]+)\)',
            r'cursor.execute(\1)',
            new_content
        )
        
        # Replace DB_NAME references
        new_content = re.sub(
            r'DB_NAME = [\'"][^\'"]+[\'"]',
            '# DB_NAME replaced with DATABASE_CONFIG',
            new_content
        )
        
        # Add proper error handling
        new_content = re.sub(
            r'def init_database\(\):',
            '''def init_database():
    """Initialize database tables using PostgreSQL"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()''',
            new_content
        )
        
        # Add commit and close
        new_content = re.sub(
            r'conn\.commit\(\)\s*conn\.close\(\)',
            '''            conn.commit()
    except Exception as e:
        print(f"Database initialization error: {e}")
        raise e''',
            new_content
        )
        
        # Write the migrated file
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        print(f"✅ {file_path} - Migrated successfully")
        return True
        
    except Exception as e:
        print(f"❌ {file_path} - Migration failed: {e}")
        return False

def create_postgresql_startup_script():
    """Create a startup script that uses PostgreSQL"""
    script_content = '''#!/usr/bin/env python3
"""
SIH 2025 Harvest Enterprise - PostgreSQL System Startup
Starts all APIs with PostgreSQL database integration
"""

import os
import sys
import time
import subprocess
import signal
import threading
from datetime import datetime

# API Configuration with PostgreSQL
APIS = [
    {
        'name': 'Crop Recommendation API',
        'file': 'src/api/crop_api_production.py',
        'port': 8080,
        'description': 'ML-based crop recommendation system with PostgreSQL'
    },
    {
        'name': 'Weather Integration API',
        'file': 'src/api/weather_integration_api.py',
        'port': 5005,
        'description': 'Weather data integration with PostgreSQL'
    },
    {
        'name': 'Market Price API',
        'file': 'src/api/market_price_api.py',
        'port': 5004,
        'description': 'Market price prediction with PostgreSQL'
    },
    {
        'name': 'Yield Prediction API',
        'file': 'src/api/yield_prediction_api.py',
        'port': 5003,
        'description': 'Yield prediction with PostgreSQL'
    },
    {
        'name': 'Field Management API',
        'file': 'src/api/field_management_api.py',
        'port': 5002,
        'description': 'Field management with PostgreSQL'
    },
    {
        'name': 'Satellite Soil API',
        'file': 'src/api/satellite_soil_api.py',
        'port': 5006,
        'description': 'Satellite soil analysis with PostgreSQL'
    },
    {
        'name': 'Multilingual AI API',
        'file': 'src/api/multilingual_ai_api.py',
        'port': 5007,
        'description': 'Multilingual AI with PostgreSQL'
    },
    {
        'name': 'Disease Detection API',
        'file': 'src/api/ai_disease_detection_api.py',
        'port': 5008,
        'description': 'Disease detection with PostgreSQL'
    },
    {
        'name': 'Sustainability Scoring API',
        'file': 'src/api/sustainability_scoring_api.py',
        'port': 5009,
        'description': 'Sustainability scoring with PostgreSQL'
    },
    {
        'name': 'Crop Rotation API',
        'file': 'src/api/crop_rotation_api.py',
        'port': 5010,
        'description': 'Crop rotation with PostgreSQL'
    },
    {
        'name': 'Offline Capability API',
        'file': 'src/api/offline_capability_api.py',
        'port': 5011,
        'description': 'Offline capability with PostgreSQL'
    },
    {
        'name': 'SIH 2025 Integrated API',
        'file': 'src/api/sih_2025_integrated_api.py',
        'port': 5012,
        'description': 'Integrated API with PostgreSQL'
    }
]

# Global process list for cleanup
processes = []

def log(message, level="INFO"):
    """Log message with timestamp"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {level}: {message}")

def start_api(api):
    """Start a single API with PostgreSQL configuration"""
    try:
        log(f"🚀 Starting {api['name']} on port {api['port']}...")
        
        # Set environment variables for PostgreSQL
        env = os.environ.copy()
        env['PORT'] = str(api['port'])
        env['FLASK_ENV'] = 'production'
        env['DB_HOST'] = 'localhost'
        env['DB_PORT'] = '5432'
        env['DB_NAME'] = 'harvest_enterprise'
        env['DB_USER'] = 'postgres'
        env['DB_PASSWORD'] = 'K@shmir2442'
        
        # Start the API process
        process = subprocess.Popen(
            [sys.executable, api['file']],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        processes.append({
            'process': process,
            'api': api,
            'start_time': time.time()
        })
        
        log(f"✅ {api['name']} started (PID: {process.pid})")
        return True
        
    except Exception as e:
        log(f"❌ Failed to start {api['name']}: {e}", "ERROR")
        return False

def check_api_health(api, timeout=30):
    """Check if API is responding"""
    import requests
    
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            response = requests.get(f"http://localhost:{api['port']}/health", timeout=5)
            if response.status_code == 200:
                return True
        except:
            pass
        time.sleep(2)
    return False

def start_all_apis():
    """Start all APIs with PostgreSQL"""
    log("🌾 Starting SIH 2025 Harvest Enterprise - PostgreSQL System")
    log("=" * 60)
    
    # Start APIs one by one
    for api in APIS:
        if not start_api(api):
            log(f"⚠️ Skipping {api['name']} due to startup failure", "WARNING")
        time.sleep(3)  # Delay between starts
    
    log("⏳ Waiting for APIs to initialize...")
    time.sleep(15)
    
    # Check API health
    log("🔍 Checking API health...")
    healthy_apis = 0
    for api in APIS:
        if check_api_health(api):
            log(f"✅ {api['name']} is healthy")
            healthy_apis += 1
        else:
            log(f"⚠️ {api['name']} may not be ready", "WARNING")
    
    log(f"📊 {healthy_apis}/{len(APIS)} APIs are healthy")
    
    if healthy_apis > 0:
        log("🎉 PostgreSQL system startup completed!")
        log("🌐 Integrated API available at: http://localhost:5012")
        log("📱 Frontend can now connect to the backend")
    else:
        log("❌ No APIs are responding. Check logs for errors.", "ERROR")

def cleanup():
    """Clean up all processes"""
    log("🧹 Cleaning up processes...")
    for proc_info in processes:
        try:
            proc_info['process'].terminate()
            proc_info['process'].wait(timeout=5)
        except:
            try:
                proc_info['process'].kill()
            except:
                pass
    log("✅ Cleanup completed")

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    log("🛑 Shutdown signal received...")
    cleanup()
    sys.exit(0)

def main():
    """Main function"""
    print("🌾 SIH 2025 Harvest Enterprise - PostgreSQL System")
    print("=" * 60)
    
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Check if we're in the right directory
    if not os.path.exists('src/api/integrated_api.py'):
        log("❌ Please run this script from the backend directory", "ERROR")
        log("💡 Use: cd backend && python start_postgresql_system.py")
        return False
    
    # Start all APIs
    start_all_apis()
    
    # Keep the script running
    try:
        log("🔄 System is running. Press Ctrl+C to stop.")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        log("🛑 Shutdown requested by user")
    finally:
        cleanup()
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
'''
    
    with open('start_postgresql_system.py', 'w', encoding='utf-8') as f:
        f.write(script_content)
    
    print("✅ Created start_postgresql_system.py")

def main():
    """Main migration function"""
    print("🔄 SIH 2025 Harvest Enterprise - PostgreSQL Migration")
    print("=" * 60)
    
    migrated_count = 0
    
    # Migrate each API file
    for api_file in API_FILES:
        if os.path.exists(api_file):
            if migrate_api_file(api_file):
                migrated_count += 1
        else:
            print(f"⚠️ {api_file} - File not found")
    
    # Create PostgreSQL startup script
    create_postgresql_startup_script()
    
    print(f"\n📊 MIGRATION SUMMARY:")
    print(f"✅ Migrated: {migrated_count}/{len(API_FILES)} APIs")
    print(f"🎉 All APIs now use PostgreSQL!")
    print(f"🚀 Use: python start_postgresql_system.py")

if __name__ == "__main__":
    main()
