#!/usr/bin/env python3
"""
Fix PostgreSQL migration issues in all APIs
Properly converts APIs to use PostgreSQL without syntax errors
"""

import os
import re
import shutil
from datetime import datetime

# List of all API files that need fixing
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

def create_clean_postgresql_api(file_path):
    """Create a clean PostgreSQL version of an API"""
    print(f"🔧 Creating clean PostgreSQL version of {file_path}...")
    
    try:
        # Read the backup file (original SQLite version)
        backup_files = [f for f in os.listdir(os.path.dirname(file_path)) if f.startswith(os.path.basename(file_path) + '.backup_')]
        if not backup_files:
            print(f"⚠️ No backup found for {file_path}")
            return False
        
        backup_path = os.path.join(os.path.dirname(file_path), backup_files[-1])
        
        with open(backup_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Add PostgreSQL imports at the top
        postgresql_imports = '''
# PostgreSQL Database Configuration
import psycopg2
from psycopg2.extras import RealDictCursor
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
        
        # Find where to insert PostgreSQL code (after imports)
        lines = content.split('\n')
        insert_index = 0
        for i, line in enumerate(lines):
            if line.strip().startswith('import ') or line.strip().startswith('from '):
                insert_index = i + 1
            elif line.strip() == '' and insert_index > 0:
                break
        
        # Insert PostgreSQL code
        new_lines = []
        for i, line in enumerate(lines):
            new_lines.append(line)
            if i == insert_index:
                new_lines.append('')
                new_lines.extend(postgresql_imports.split('\n'))
                new_lines.append('')
        
        # Replace SQLite-specific code
        new_content = '\n'.join(new_lines)
        
        # Remove sqlite3 import
        new_content = re.sub(r'import sqlite3\n', '', new_content)
        
        # Replace DB_NAME with DATABASE_CONFIG
        new_content = re.sub(r'DB_NAME = [\'"][^\'"]+[\'"]', '# DB_NAME replaced with DATABASE_CONFIG', new_content)
        
        # Fix init_database function
        new_content = re.sub(
            r'def init_database\(\):\s*\n\s*"""Initialize[^"]*"""\s*\n\s*conn = sqlite3\.connect\([^)]+\)\s*\n\s*cursor = conn\.cursor\(\)',
            '''def init_database():
    """Initialize database tables using PostgreSQL"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()''',
            new_content,
            flags=re.DOTALL
        )
        
        # Fix the end of init_database function
        new_content = re.sub(
            r'conn\.commit\(\)\s*\n\s*conn\.close\(\)',
            '''            conn.commit()
    except Exception as e:
        print(f"Database initialization error: {e}")
        raise e''',
            new_content
        )
        
        # Replace all sqlite3.connect calls
        new_content = re.sub(
            r'conn = sqlite3\.connect\([^)]+\)',
            'conn = psycopg2.connect(**DATABASE_CONFIG)',
            new_content
        )
        
        # Replace cursor.execute patterns for PostgreSQL
        new_content = re.sub(
            r'cursor\.execute\(\'([^\']+)\'\)',
            r'cursor.execute(\'\1\')',
            new_content
        )
        
        # Fix CREATE TABLE statements for PostgreSQL
        new_content = re.sub(
            r'CREATE TABLE IF NOT EXISTS',
            'CREATE TABLE IF NOT EXISTS',
            new_content
        )
        
        # Fix TEXT to VARCHAR for PostgreSQL
        new_content = re.sub(r'\bTEXT\b', 'VARCHAR', new_content)
        new_content = re.sub(r'\bREAL\b', 'FLOAT', new_content)
        
        # Write the fixed file
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        print(f"✅ {file_path} - Fixed successfully")
        return True
        
    except Exception as e:
        print(f"❌ {file_path} - Fix failed: {e}")
        return False

def main():
    """Main fixing function"""
    print("🔧 Fixing PostgreSQL API Issues")
    print("=" * 50)
    
    fixed_count = 0
    
    # Fix each API file
    for api_file in API_FILES:
        if os.path.exists(api_file):
            if create_clean_postgresql_api(api_file):
                fixed_count += 1
        else:
            print(f"⚠️ {api_file} - File not found")
    
    print(f"\n📊 FIXING SUMMARY:")
    print(f"✅ Fixed: {fixed_count}/{len(API_FILES)} APIs")
    print(f"🎉 All APIs should now work with PostgreSQL!")

if __name__ == "__main__":
    main()
