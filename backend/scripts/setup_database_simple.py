#!/usr/bin/env python3
"""
Simple Database Setup for SIH 2025 Harvest Enterprise
Creates PostgreSQL database tables for all APIs
"""

import os
import sys
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

def create_database():
    """Create the harvest_enterprise database if it doesn't exist"""
    try:
        # Get password from user
        password = input("Enter PostgreSQL password for user 'postgres': ")
        
        # Connect to PostgreSQL server
        conn = psycopg2.connect(
            host="localhost",
            port="5432",
            user="postgres",
            password=password,
            database="postgres"
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # Check if database exists
        cursor.execute("SELECT 1 FROM pg_database WHERE datname = 'harvest_enterprise'")
        exists = cursor.fetchone()
        
        if not exists:
            cursor.execute("CREATE DATABASE harvest_enterprise")
            print("✅ Database 'harvest_enterprise' created successfully")
        else:
            print("✅ Database 'harvest_enterprise' already exists")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Error creating database: {e}")
        return False

def create_tables():
    """Create all necessary tables"""
    try:
        # Get password from user
        password = input("Enter PostgreSQL password for user 'postgres': ")
        
        # Connect to the harvest_enterprise database
        conn = psycopg2.connect(
            host="localhost",
            port="5432",
            user="postgres",
            password=password,
            database="harvest_enterprise"
        )
        cursor = conn.cursor()
        
        # Create tables
        tables = [
            """
            CREATE TABLE IF NOT EXISTS crop_recommendations (
                id SERIAL PRIMARY KEY,
                user_id VARCHAR(50),
                location VARCHAR(100),
                soil_type VARCHAR(50),
                climate VARCHAR(50),
                season VARCHAR(20),
                recommended_crop VARCHAR(100),
                confidence_score FLOAT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS weather_data (
                id SERIAL PRIMARY KEY,
                location VARCHAR(100),
                date DATE,
                temperature FLOAT,
                humidity FLOAT,
                rainfall FLOAT,
                wind_speed FLOAT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS market_prices (
                id SERIAL PRIMARY KEY,
                crop_name VARCHAR(100),
                location VARCHAR(100),
                price_per_kg FLOAT,
                date DATE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS yield_predictions (
                id SERIAL PRIMARY KEY,
                user_id VARCHAR(50),
                crop_name VARCHAR(100),
                location VARCHAR(100),
                predicted_yield FLOAT,
                confidence FLOAT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS field_management (
                id SERIAL PRIMARY KEY,
                user_id VARCHAR(50),
                field_name VARCHAR(100),
                location VARCHAR(100),
                area FLOAT,
                soil_type VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS satellite_soil_data (
                id SERIAL PRIMARY KEY,
                location VARCHAR(100),
                soil_moisture FLOAT,
                soil_temperature FLOAT,
                ndvi FLOAT,
                date DATE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS multilingual_ai (
                id SERIAL PRIMARY KEY,
                user_id VARCHAR(50),
                language VARCHAR(10),
                query TEXT,
                response TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS disease_detection (
                id SERIAL PRIMARY KEY,
                user_id VARCHAR(50),
                image_path VARCHAR(255),
                disease_name VARCHAR(100),
                confidence FLOAT,
                treatment_suggestion TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS sustainability_scores (
                id SERIAL PRIMARY KEY,
                user_id VARCHAR(50),
                field_id VARCHAR(50),
                water_usage FLOAT,
                carbon_footprint FLOAT,
                soil_health FLOAT,
                overall_score FLOAT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS crop_rotation (
                id SERIAL PRIMARY KEY,
                user_id VARCHAR(50),
                field_id VARCHAR(50),
                current_crop VARCHAR(100),
                next_crop VARCHAR(100),
                rotation_plan TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS offline_capability (
                id SERIAL PRIMARY KEY,
                user_id VARCHAR(50),
                data_type VARCHAR(50),
                data_content TEXT,
                sync_status VARCHAR(20),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """
        ]
        
        for table_sql in tables:
            cursor.execute(table_sql)
            print(f"✅ Table created/verified: {table_sql.split('(')[0].split()[-1]}")
        
        conn.commit()
        cursor.close()
        conn.close()
        
        print("✅ All tables created successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        return False

def main():
    print("🌾 SIH 2025 Harvest Enterprise - Simple Database Setup")
    print("=" * 50)
    
    print("\n1️⃣ Creating database...")
    if not create_database():
        return False
    
    print("\n2️⃣ Creating tables...")
    if not create_tables():
        return False
    
    print("\n✅ Database setup completed successfully!")
    print("🚀 You can now start the system with: python scripts/start_system_postgresql.py")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
