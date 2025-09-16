"""
Database Setup Script for SIH 2025 Harvest Enterprise App
Sets up PostgreSQL database and creates all required tables
"""

import os
import sys
import subprocess
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import logging

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.database import DATABASE_CONFIG, init_database, test_connection, health_check

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def check_postgresql_installed():
    """Check if PostgreSQL is installed"""
    try:
        result = subprocess.run(['psql', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ PostgreSQL found: {result.stdout.strip()}")
            return True
        else:
            print("❌ PostgreSQL not found")
            return False
    except FileNotFoundError:
        print("❌ PostgreSQL not found in PATH")
        return False

def create_database():
    """Create the database if it doesn't exist"""
    try:
        # Connect to PostgreSQL server (not specific database)
        conn = psycopg2.connect(
            host=DATABASE_CONFIG['host'],
            port=DATABASE_CONFIG['port'],
            user=DATABASE_CONFIG['username'],
            password=DATABASE_CONFIG['password'],
            database='postgres'  # Connect to default postgres database
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # Check if database exists
        cursor.execute(f"SELECT 1 FROM pg_database WHERE datname = '{DATABASE_CONFIG['database']}'")
        exists = cursor.fetchone()
        
        if not exists:
            # Create database
            cursor.execute(f"CREATE DATABASE {DATABASE_CONFIG['database']}")
            print(f"✅ Database '{DATABASE_CONFIG['database']}' created successfully")
        else:
            print(f"✅ Database '{DATABASE_CONFIG['database']}' already exists")
        
        cursor.close()
        conn.close()
        return True
        
    except psycopg2.OperationalError as e:
        print(f"❌ Error connecting to PostgreSQL: {e}")
        print("\n🔧 Setup Instructions:")
        print("1. Install PostgreSQL: https://www.postgresql.org/download/")
        print("2. Start PostgreSQL service")
        print("3. Create a user and database:")
        print(f"   CREATE USER {DATABASE_CONFIG['username']} WITH PASSWORD '{DATABASE_CONFIG['password']}';")
        print(f"   CREATE DATABASE {DATABASE_CONFIG['database']} OWNER {DATABASE_CONFIG['username']};")
        print("4. Grant privileges:")
        print(f"   GRANT ALL PRIVILEGES ON DATABASE {DATABASE_CONFIG['database']} TO {DATABASE_CONFIG['username']};")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

def install_requirements():
    """Install Python requirements"""
    try:
        print("📦 Installing Python requirements...")
        result = subprocess.run([
            sys.executable, '-m', 'pip', 'install', '-r', 'requirements.txt'
        ], cwd=os.path.join(os.path.dirname(__file__), '..'), capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Requirements installed successfully")
            return True
        else:
            print(f"❌ Error installing requirements: {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ Error installing requirements: {e}")
        return False

def setup_environment():
    """Setup environment variables"""
    env_file = os.path.join(os.path.dirname(__file__), '..', '.env')
    
    if not os.path.exists(env_file):
        print("📝 Creating .env file...")
        with open(env_file, 'w') as f:
            f.write(f"""# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=harvest_enterprise
DB_USER=harvest_user
DB_PASSWORD=harvest_password

# API Configuration
FLASK_ENV=development
FLASK_DEBUG=True
""")
        print("✅ .env file created")
    else:
        print("✅ .env file already exists")

def main():
    """Main setup function"""
    print("🌾 SIH 2025 Harvest Enterprise - Database Setup")
    print("=" * 50)
    
    # Step 1: Check PostgreSQL installation
    print("\n1️⃣ Checking PostgreSQL installation...")
    if not check_postgresql_installed():
        print("\n❌ Please install PostgreSQL first:")
        print("   Windows: Download from https://www.postgresql.org/download/windows/")
        print("   macOS: brew install postgresql")
        print("   Ubuntu: sudo apt-get install postgresql postgresql-contrib")
        return False
    
    # Step 2: Install Python requirements
    print("\n2️⃣ Installing Python requirements...")
    if not install_requirements():
        print("❌ Failed to install requirements")
        return False
    
    # Step 3: Setup environment
    print("\n3️⃣ Setting up environment...")
    setup_environment()
    
    # Step 4: Create database
    print("\n4️⃣ Creating database...")
    if not create_database():
        print("❌ Failed to create database")
        return False
    
    # Step 5: Initialize tables
    print("\n5️⃣ Creating database tables...")
    if not init_database():
        print("❌ Failed to create tables")
        return False
    
    # Step 6: Test connection
    print("\n6️⃣ Testing database connection...")
    if not test_connection():
        print("❌ Database connection test failed")
        return False
    
    # Step 7: Health check
    print("\n7️⃣ Running health check...")
    if not health_check():
        print("❌ Database health check failed")
        return False
    
    print("\n🎉 Database setup completed successfully!")
    print("\n📋 Next steps:")
    print("1. Start the APIs: python scripts/start_system.py")
    print("2. Test the system: python scripts/quick_test.py")
    print("3. Access the integrated API: http://localhost:5012")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

