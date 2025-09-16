"""
Weather Integration API - Simple PostgreSQL Version
Provides real-time weather data and forecasts
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import psycopg2
from psycopg2.extras import RealDictCursor
import requests
import os
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import random
from contextlib import contextmanager

# Fix import paths for direct execution
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

app = Flask(__name__)
CORS(app)

# PostgreSQL Database Configuration
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

# OpenWeatherMap API configuration
OPENWEATHER_API_KEY = os.getenv('OPENWEATHER_API_KEY', 'your_api_key_here')
OPENWEATHER_BASE_URL = 'https://api.openweathermap.org/data/2.5'

def init_database():
    """Initialize database tables using PostgreSQL"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Weather data table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS weather_data (
                    id VARCHAR PRIMARY KEY,
                    location VARCHAR NOT NULL,
                    latitude FLOAT NOT NULL,
                    longitude FLOAT NOT NULL,
                    temperature FLOAT NOT NULL,
                    humidity FLOAT NOT NULL,
                    pressure FLOAT NOT NULL,
                    wind_speed FLOAT NOT NULL,
                    wind_direction FLOAT NOT NULL,
                    visibility FLOAT NOT NULL,
                    uv_index FLOAT NOT NULL,
                    weather_condition VARCHAR NOT NULL,
                    weather_description VARCHAR NOT NULL,
                    cloudiness FLOAT NOT NULL,
                    rain_1h FLOAT,
                    snow_1h FLOAT,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Weather forecasts table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS weather_forecasts (
                    id VARCHAR PRIMARY KEY,
                    location VARCHAR NOT NULL,
                    latitude FLOAT NOT NULL,
                    longitude FLOAT NOT NULL,
                    forecast_date DATE NOT NULL,
                    temperature_min FLOAT NOT NULL,
                    temperature_max FLOAT NOT NULL,
                    humidity FLOAT NOT NULL,
                    pressure FLOAT NOT NULL,
                    wind_speed FLOAT NOT NULL,
                    wind_direction FLOAT NOT NULL,
                    weather_condition VARCHAR NOT NULL,
                    weather_description VARCHAR NOT NULL,
                    precipitation_probability FLOAT NOT NULL,
                    uv_index FLOAT NOT NULL,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            conn.commit()
            print("✅ Weather database tables initialized successfully")
            
    except Exception as e:
        print(f"❌ Database initialization error: {e}")
        raise e

# Initialize database
init_database()

def get_weather_data(latitude: float, longitude: float) -> Dict:
    """Get current weather data for given coordinates"""
    try:
        # For demo purposes, return mock data
        # In production, this would call OpenWeatherMap API
        weather_data = {
            'location': f"Location {latitude:.2f}, {longitude:.2f}",
            'latitude': latitude,
            'longitude': longitude,
            'temperature': round(random.uniform(15, 35), 1),
            'humidity': round(random.uniform(40, 90), 1),
            'pressure': round(random.uniform(1000, 1020), 1),
            'wind_speed': round(random.uniform(0, 15), 1),
            'wind_direction': round(random.uniform(0, 360), 1),
            'visibility': round(random.uniform(5, 20), 1),
            'uv_index': round(random.uniform(0, 10), 1),
            'weather_condition': random.choice(['Clear', 'Cloudy', 'Rainy', 'Sunny']),
            'weather_description': random.choice(['Clear sky', 'Partly cloudy', 'Light rain', 'Sunny']),
            'cloudiness': round(random.uniform(0, 100), 1),
            'rain_1h': round(random.uniform(0, 5), 1),
            'snow_1h': 0,
            'timestamp': datetime.now().isoformat()
        }
        
        # Store in database
        with get_db_cursor() as (cursor, conn):
            cursor.execute('''
                INSERT INTO weather_data 
                (id, location, latitude, longitude, temperature, humidity, pressure, 
                 wind_speed, wind_direction, visibility, uv_index, weather_condition, 
                 weather_description, cloudiness, rain_1h, snow_1h)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                temperature = EXCLUDED.temperature,
                humidity = EXCLUDED.humidity,
                pressure = EXCLUDED.pressure,
                wind_speed = EXCLUDED.wind_speed,
                wind_direction = EXCLUDED.wind_direction,
                visibility = EXCLUDED.visibility,
                uv_index = EXCLUDED.uv_index,
                weather_condition = EXCLUDED.weather_condition,
                weather_description = EXCLUDED.weather_description,
                cloudiness = EXCLUDED.cloudiness,
                rain_1h = EXCLUDED.rain_1h,
                snow_1h = EXCLUDED.snow_1h,
                timestamp = CURRENT_TIMESTAMP
            ''', (
                f"weather_{latitude}_{longitude}_{datetime.now().strftime('%Y%m%d%H')}",
                weather_data['location'],
                weather_data['latitude'],
                weather_data['longitude'],
                weather_data['temperature'],
                weather_data['humidity'],
                weather_data['pressure'],
                weather_data['wind_speed'],
                weather_data['wind_direction'],
                weather_data['visibility'],
                weather_data['uv_index'],
                weather_data['weather_condition'],
                weather_data['weather_description'],
                weather_data['cloudiness'],
                weather_data['rain_1h'],
                weather_data['snow_1h']
            ))
            conn.commit()
        
        return weather_data
        
    except Exception as e:
        print(f"Error getting weather data: {e}")
        return {'error': str(e)}

def get_weather_forecast(latitude: float, longitude: float, days: int = 5) -> List[Dict]:
    """Get weather forecast for given coordinates"""
    try:
        forecasts = []
        
        for i in range(days):
            forecast_date = datetime.now() + timedelta(days=i)
            forecast = {
                'date': forecast_date.strftime('%Y-%m-%d'),
                'temperature_min': round(random.uniform(10, 25), 1),
                'temperature_max': round(random.uniform(25, 40), 1),
                'humidity': round(random.uniform(40, 90), 1),
                'pressure': round(random.uniform(1000, 1020), 1),
                'wind_speed': round(random.uniform(0, 15), 1),
                'wind_direction': round(random.uniform(0, 360), 1),
                'weather_condition': random.choice(['Clear', 'Cloudy', 'Rainy', 'Sunny']),
                'weather_description': random.choice(['Clear sky', 'Partly cloudy', 'Light rain', 'Sunny']),
                'precipitation_probability': round(random.uniform(0, 100), 1),
                'uv_index': round(random.uniform(0, 10), 1)
            }
            forecasts.append(forecast)
        
        return forecasts
        
    except Exception as e:
        print(f"Error getting weather forecast: {e}")
        return [{'error': str(e)}]

# API Routes
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Weather Integration API',
        'version': '1.0.0',
        'database': 'PostgreSQL',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/weather/current', methods=['GET'])
def get_current_weather():
    """Get current weather data"""
    try:
        latitude = float(request.args.get('lat', 28.6139))  # Default to Delhi
        longitude = float(request.args.get('lon', 77.2090))
        
        weather_data = get_weather_data(latitude, longitude)
        
        return jsonify({
            'success': True,
            'data': weather_data,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/weather/forecast', methods=['GET'])
def get_forecast():
    """Get weather forecast"""
    try:
        latitude = float(request.args.get('lat', 28.6139))  # Default to Delhi
        longitude = float(request.args.get('lon', 77.2090))
        days = int(request.args.get('days', 5))
        
        forecasts = get_weather_forecast(latitude, longitude, days)
        
        return jsonify({
            'success': True,
            'data': {
                'location': f"{latitude}, {longitude}",
                'forecasts': forecasts
            },
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/weather/history', methods=['GET'])
def get_weather_history():
    """Get historical weather data"""
    try:
        latitude = float(request.args.get('lat', 28.6139))
        longitude = float(request.args.get('lon', 77.2090))
        days = int(request.args.get('days', 7))
        
        with get_db_cursor() as (cursor, conn):
            cursor.execute('''
                SELECT * FROM weather_data 
                WHERE latitude = %s AND longitude = %s 
                AND timestamp >= %s
                ORDER BY timestamp DESC
                LIMIT %s
            ''', (latitude, longitude, datetime.now() - timedelta(days=days), days * 24))
            
            history = cursor.fetchall()
        
        return jsonify({
            'success': True,
            'data': [dict(row) for row in history],
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

if __name__ == '__main__':
    print("🌤️ Starting Weather Integration API...")
    print("✅ Database initialized")
    print("✅ API ready!")
    
    port = int(os.environ.get('PORT', 5005))
    app.run(host='0.0.0.0', port=port, debug=False)
