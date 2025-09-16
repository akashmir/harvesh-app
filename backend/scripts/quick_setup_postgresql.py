"""
Quick PostgreSQL Setup for SIH 2025 Harvest Enterprise App
Automated setup script for Windows, macOS, and Linux
"""

import os
import sys
import subprocess
import platform
import urllib.request
import zipfile
import shutil

def check_python_version():
    """Check if Python version is compatible"""
    if sys.version_info < (3, 8):
        print("❌ Python 3.8 or higher is required")
        print(f"Current version: {sys.version}")
        return False
    print(f"✅ Python {sys.version.split()[0]} is compatible")
    return True

def install_postgresql_windows():
    """Install PostgreSQL on Windows"""
    print("🪟 Installing PostgreSQL on Windows...")
    
    # Check if PostgreSQL is already installed
    try:
        result = subprocess.run(['psql', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ PostgreSQL already installed: {result.stdout.strip()}")
            return True
    except FileNotFoundError:
        pass
    
    print("📥 Downloading PostgreSQL installer...")
    # Download PostgreSQL installer
    installer_url = "https://get.enterprisedb.com/postgresql/postgresql-15.4-1-windows-x64.exe"
    installer_path = "postgresql-installer.exe"
    
    try:
        urllib.request.urlretrieve(installer_url, installer_path)
        print("✅ Installer downloaded successfully")
        
        print("🚀 Running PostgreSQL installer...")
        print("⚠️ Please follow the installer prompts:")
        print("   - Set password for 'postgres' user")
        print("   - Remember the password for database setup")
        print("   - Complete the installation")
        
        # Run installer
        subprocess.run([installer_path], check=True)
        
        # Clean up
        os.remove(installer_path)
        
        print("✅ PostgreSQL installation completed")
        return True
        
    except Exception as e:
        print(f"❌ Error installing PostgreSQL: {e}")
        print("💡 Please install PostgreSQL manually from: https://www.postgresql.org/download/windows/")
        return False

def install_postgresql_macos():
    """Install PostgreSQL on macOS"""
    print("🍎 Installing PostgreSQL on macOS...")
    
    try:
        # Check if Homebrew is installed
        result = subprocess.run(['brew', '--version'], capture_output=True, text=True)
        if result.returncode != 0:
            print("📦 Installing Homebrew first...")
            subprocess.run([
                '/bin/bash', '-c', 
                '$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)'
            ], check=True)
        
        # Install PostgreSQL
        subprocess.run(['brew', 'install', 'postgresql@15'], check=True)
        subprocess.run(['brew', 'services', 'start', 'postgresql@15'], check=True)
        
        print("✅ PostgreSQL installed and started")
        return True
        
    except Exception as e:
        print(f"❌ Error installing PostgreSQL: {e}")
        print("💡 Please install PostgreSQL manually: brew install postgresql@15")
        return False

def install_postgresql_linux():
    """Install PostgreSQL on Linux"""
    print("🐧 Installing PostgreSQL on Linux...")
    
    try:
        # Detect package manager
        if shutil.which('apt-get'):
            subprocess.run(['sudo', 'apt-get', 'update'], check=True)
            subprocess.run(['sudo', 'apt-get', 'install', '-y', 'postgresql', 'postgresql-contrib'], check=True)
        elif shutil.which('yum'):
            subprocess.run(['sudo', 'yum', 'install', '-y', 'postgresql-server', 'postgresql-contrib'], check=True)
            subprocess.run(['sudo', 'postgresql-setup', 'initdb'], check=True)
        elif shutil.which('dnf'):
            subprocess.run(['sudo', 'dnf', 'install', '-y', 'postgresql-server', 'postgresql-contrib'], check=True)
            subprocess.run(['sudo', 'postgresql-setup', 'initdb'], check=True)
        else:
            print("❌ Unsupported package manager")
            return False
        
        # Start PostgreSQL service
        subprocess.run(['sudo', 'systemctl', 'start', 'postgresql'], check=True)
        subprocess.run(['sudo', 'systemctl', 'enable', 'postgresql'], check=True)
        
        print("✅ PostgreSQL installed and started")
        return True
        
    except Exception as e:
        print(f"❌ Error installing PostgreSQL: {e}")
        print("💡 Please install PostgreSQL manually: sudo apt-get install postgresql postgresql-contrib")
        return False

def setup_database_user():
    """Setup database user and permissions"""
    print("👤 Setting up database user...")
    
    try:
        # Create user and database
        commands = [
            "CREATE USER harvest_user WITH PASSWORD 'harvest_password';",
            "CREATE DATABASE harvest_enterprise OWNER harvest_user;",
            "GRANT ALL PRIVILEGES ON DATABASE harvest_enterprise TO harvest_user;",
            "ALTER USER harvest_user CREATEDB;"
        ]
        
        for command in commands:
            subprocess.run([
                'psql', '-U', 'postgres', '-c', command
            ], check=True, capture_output=True)
        
        print("✅ Database user and database created successfully")
        return True
        
    except Exception as e:
        print(f"❌ Error setting up database user: {e}")
        print("💡 Please run these commands manually:")
        print("   sudo -u postgres psql")
        print("   CREATE USER harvest_user WITH PASSWORD 'harvest_password';")
        print("   CREATE DATABASE harvest_enterprise OWNER harvest_user;")
        print("   GRANT ALL PRIVILEGES ON DATABASE harvest_enterprise TO harvest_user;")
        print("   \q")
        return False

def install_python_requirements():
    """Install Python requirements"""
    print("📦 Installing Python requirements...")
    
    try:
        subprocess.run([
            sys.executable, '-m', 'pip', 'install', '-r', 'requirements.txt'
        ], check=True)
        
        print("✅ Python requirements installed successfully")
        return True
        
    except Exception as e:
        print(f"❌ Error installing requirements: {e}")
        return False

def create_env_file():
    """Create environment configuration file"""
    print("📝 Creating environment configuration...")
    
    env_content = """# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=harvest_enterprise
DB_USER=harvest_user
DB_PASSWORD=harvest_password

# API Configuration
FLASK_ENV=development
FLASK_DEBUG=True
"""
    
    with open('.env', 'w') as f:
        f.write(env_content)
    
    print("✅ Environment configuration created")
    return True

def main():
    """Main setup function"""
    print("SIH 2025 Harvest Enterprise - Quick PostgreSQL Setup")
    print("=" * 60)
    
    # Check Python version
    if not check_python_version():
        return False
    
    # Detect operating system
    system = platform.system().lower()
    print(f"🖥️ Detected OS: {system}")
    
    # Install PostgreSQL based on OS
    if system == 'windows':
        if not install_postgresql_windows():
            return False
    elif system == 'darwin':  # macOS
        if not install_postgresql_macos():
            return False
    elif system == 'linux':
        if not install_postgresql_linux():
            return False
    else:
        print(f"❌ Unsupported operating system: {system}")
        return False
    
    # Setup database user
    if not setup_database_user():
        return False
    
    # Install Python requirements
    if not install_python_requirements():
        return False
    
    # Create environment file
    if not create_env_file():
        return False
    
    # Run database setup
    print("🗄️ Setting up database tables...")
    try:
        subprocess.run([sys.executable, 'scripts/setup_database.py'], check=True)
        print("✅ Database tables created successfully")
    except Exception as e:
        print(f"❌ Error setting up database tables: {e}")
        return False
    
    print("\n🎉 Setup completed successfully!")
    print("\n📋 Next steps:")
    print("1. Start the system: python scripts/start_system_postgresql.py")
    print("2. Test the APIs: python scripts/quick_test.py")
    print("3. Access the integrated API: http://localhost:5012")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
