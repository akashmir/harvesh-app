"""
Weather Integration API
Provides real-time weather data, forecasts, and weather-based agricultural recommendations
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import requests
import os
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import random



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


# Fix import paths for direct execution
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


app = Flask(__name__)
CORS(app)

# Database setup
# DB_NAME replaced with DATABASE_CONFIG

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
            precipitation FLOAT NOT NULL,
            weather_condition VARCHAR NOT NULL,
            weather_description VARCHAR NOT NULL,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Agricultural weather alerts table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS weather_alerts (
            id VARCHAR PRIMARY KEY,
            location VARCHAR NOT NULL,
            alert_type VARCHAR NOT NULL,
            severity VARCHAR NOT NULL,
            message VARCHAR NOT NULL,
            start_date DATE NOT NULL,
            end_date DATE NOT NULL,
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
                conn.commit()
    except Exception as e:
        print(f"Database initialization error: {e}")
        raise e

# Initialize database
init_database()

# Weather-based crop recommendations
WEATHER_CROP_RECOMMENDATIONS = {
    'hot_dry': {
        'crops': ['Cotton', 'Sugarcane', 'Sorghum', 'Millet'],
        'description': 'Hot and dry conditions are suitable for drought-resistant crops',
        'irrigation': 'High irrigation needs',
        'planting_time': 'Early morning or late evening'
    },
    'hot_humid': {
        'crops': ['Rice', 'Maize', 'Sugarcane', 'Banana'],
        'description': 'Hot and humid conditions are ideal for tropical crops',
        'irrigation': 'Moderate irrigation with good drainage',
        'planting_time': 'Early morning'
    },
    'cool_dry': {
        'crops': ['Wheat', 'Barley', 'Oats', 'Potato'],
        'description': 'Cool and dry conditions are perfect for temperate crops',
        'irrigation': 'Low to moderate irrigation',
        'planting_time': 'Mid-morning'
    },
    'cool_humid': {
        'crops': ['Rice', 'Wheat', 'Barley', 'Potato'],
        'description': 'Cool and humid conditions suit many staple crops',
        'irrigation': 'Moderate irrigation',
        'planting_time': 'Mid-morning'
    },
    'rainy': {
        'crops': ['Rice', 'Maize', 'Sugarcane', 'Banana'],
        'description': 'Rainy conditions are excellent for water-loving crops',
        'irrigation': 'Minimal irrigation needed',
        'planting_time': 'After rain stops'
    },
    'stormy': {
        'crops': [],
        'description': 'Avoid planting during stormy weather',
        'irrigation': 'Drainage is critical',
        'planting_time': 'Wait for weather to clear'
    },
    'moderate': {
        'crops': ['Rice', 'Wheat', 'Maize', 'Cotton'],
        'description': 'Moderate weather conditions suitable for most crops',
        'irrigation': 'Regular irrigation schedule',
        'planting_time': 'Any time of day'
    }
}

# Weather impact on crops
WEATHER_IMPACT = {
    'temperature': {
        'optimal_range': (20, 30),
        'critical_high': 35,
        'critical_low': 5,
        'impact': {
            'too_hot': 'Heat stress, reduced yield, wilting',
            'too_cold': 'Frost damage, slow growth, delayed maturity',
            'optimal': 'Optimal growth and development'
        }
    },
    'humidity': {
        'optimal_range': (40, 70),
        'critical_high': 90,
        'critical_low': 20,
        'impact': {
            'too_high': 'Fungal diseases, poor pollination',
            'too_low': 'Water stress, reduced transpiration',
            'optimal': 'Healthy plant growth'
        }
    },
    'rainfall': {
        'optimal_range': (500, 1500),
        'critical_high': 2000,
        'critical_low': 200,
        'impact': {
            'too_much': 'Waterlogging, root rot, nutrient leaching',
            'too_little': 'Drought stress, reduced yield',
            'optimal': 'Adequate water supply'
        }
    },
    'wind': {
        'optimal_range': (5, 15),
        'critical_high': 25,
        'critical_low': 0,
        'impact': {
            'too_strong': 'Physical damage, lodging, soil erosion',
            'too_weak': 'Poor pollination, pest buildup',
            'optimal': 'Good air circulation'
        }
    }
}

def get_weather_condition(temperature, humidity, wind_speed, precipitation):
    """Determine weather condition based on parameters"""
    if wind_speed > 20 or precipitation > 50:
        return 'stormy'
    elif precipitation > 10:
        return 'rainy'
    elif temperature > 30 and humidity < 50:
        return 'hot_dry'
    elif temperature > 30 and humidity > 70:
        return 'hot_humid'
    elif temperature < 20 and humidity < 50:
        return 'cool_dry'
    elif temperature < 20 and humidity > 70:
        return 'cool_humid'
    else:
        return 'moderate'

def get_weather_recommendations(weather_data):
    """Get agricultural recommendations based on weather"""
    temp = weather_data.get('temperature', 25)
    humidity = weather_data.get('humidity', 50)
    wind_speed = weather_data.get('wind_speed', 10)
    precipitation = weather_data.get('precipitation', 0)
    
    condition = get_weather_condition(temp, humidity, wind_speed, precipitation)
    recommendations = WEATHER_CROP_RECOMMENDATIONS.get(condition, WEATHER_CROP_RECOMMENDATIONS['moderate'])
    
    # Add specific recommendations based on weather parameters
    specific_recommendations = []
    
    if temp > 35:
        specific_recommendations.append("🌡️ High temperature alert: Consider shade nets or mulching")
    elif temp < 5:
        specific_recommendations.append("❄️ Frost warning: Protect sensitive crops with covers")
    
    if humidity > 90:
        specific_recommendations.append("💧 High humidity: Watch for fungal diseases, ensure good ventilation")
    elif humidity < 30:
        specific_recommendations.append("🏜️ Low humidity: Increase irrigation frequency")
    
    if wind_speed > 20:
        specific_recommendations.append("💨 Strong winds: Avoid field work, check for crop damage")
    
    if precipitation > 50:
        specific_recommendations.append("🌧️ Heavy rain: Ensure proper drainage, avoid waterlogging")
    elif precipitation < 5 and temp > 25:
        specific_recommendations.append("☀️ Dry conditions: Increase irrigation, consider drought-resistant crops")
    
    return {
        'condition': condition,
        'crops': recommendations['crops'],
        'description': recommendations['description'],
        'irrigation': recommendations['irrigation'],
        'planting_time': recommendations['planting_time'],
        'specific_recommendations': specific_recommendations
    }

def get_weather_impact_analysis(weather_data):
    """Analyze weather impact on crops"""
    temp = weather_data.get('temperature', 25)
    humidity = weather_data.get('humidity', 50)
    wind_speed = weather_data.get('wind_speed', 10)
    precipitation = weather_data.get('precipitation', 0)
    
    analysis = {}
    
    # Temperature analysis
    temp_range = WEATHER_IMPACT['temperature']['optimal_range']
    if temp < temp_range[0]:
        analysis['temperature'] = {
            'status': 'too_cold',
            'impact': WEATHER_IMPACT['temperature']['impact']['too_cold'],
            'recommendation': 'Consider cold-resistant varieties or protective measures'
        }
    elif temp > temp_range[1]:
        analysis['temperature'] = {
            'status': 'too_hot',
            'impact': WEATHER_IMPACT['temperature']['impact']['too_hot'],
            'recommendation': 'Provide shade, increase irrigation, use heat-resistant varieties'
        }
    else:
        analysis['temperature'] = {
            'status': 'optimal',
            'impact': WEATHER_IMPACT['temperature']['impact']['optimal'],
            'recommendation': 'Ideal conditions for most crops'
        }
    
    # Humidity analysis
    humidity_range = WEATHER_IMPACT['humidity']['optimal_range']
    if humidity < humidity_range[0]:
        analysis['humidity'] = {
            'status': 'too_low',
            'impact': WEATHER_IMPACT['humidity']['impact']['too_low'],
            'recommendation': 'Increase irrigation, use mulching to retain moisture'
        }
    elif humidity > humidity_range[1]:
        analysis['humidity'] = {
            'status': 'too_high',
            'impact': WEATHER_IMPACT['humidity']['impact']['too_high'],
            'recommendation': 'Improve ventilation, watch for fungal diseases'
        }
    else:
        analysis['humidity'] = {
            'status': 'optimal',
            'impact': WEATHER_IMPACT['humidity']['impact']['optimal'],
            'recommendation': 'Good humidity levels for plant growth'
        }
    
    # Wind analysis
    wind_range = WEATHER_IMPACT['wind']['optimal_range']
    if wind_speed > wind_range[1]:
        analysis['wind'] = {
            'status': 'too_strong',
            'impact': WEATHER_IMPACT['wind']['impact']['too_strong'],
            'recommendation': 'Avoid field work, check for crop damage, consider windbreaks'
        }
    elif wind_speed < wind_range[0]:
        analysis['wind'] = {
            'status': 'too_weak',
            'impact': WEATHER_IMPACT['wind']['impact']['too_weak'],
            'recommendation': 'Monitor for pest buildup, ensure good air circulation'
        }
    else:
        analysis['wind'] = {
            'status': 'optimal',
            'impact': WEATHER_IMPACT['wind']['impact']['optimal'],
            'recommendation': 'Good wind conditions for crop health'
        }
    
    return analysis

def get_irrigation_recommendations(weather_data, soil_moisture=None):
    """Get irrigation recommendations based on weather"""
    temp = weather_data.get('temperature', 25)
    humidity = weather_data.get('humidity', 50)
    precipitation = weather_data.get('precipitation', 0)
    wind_speed = weather_data.get('wind_speed', 10)
    
    # Calculate evapotranspiration (simplified)
    et_rate = (temp - 10) * 0.1 * (1 - humidity/100) * (1 + wind_speed/20)
    
    # Adjust for precipitation
    net_water_need = max(0, et_rate - precipitation/10)
    
    if net_water_need > 5:
        recommendation = "High irrigation needed"
        frequency = "Daily"
        amount = "Heavy watering"
    elif net_water_need > 2:
        recommendation = "Moderate irrigation needed"
        frequency = "Every 2-3 days"
        amount = "Moderate watering"
    elif net_water_need > 0.5:
        recommendation = "Light irrigation needed"
        frequency = "Every 3-4 days"
        amount = "Light watering"
    else:
        recommendation = "No irrigation needed"
        frequency = "Monitor soil moisture"
        amount = "Natural precipitation sufficient"
    
    return {
        'recommendation': recommendation,
        'frequency': frequency,
        'amount': amount,
        'et_rate': round(et_rate, 2),
        'net_water_need': round(net_water_need, 2),
        'factors': {
            'temperature': temp,
            'humidity': humidity,
            'precipitation': precipitation,
            'wind_speed': wind_speed
        }
    }

# API Endpoints

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "success": True,
        "message": "Weather Integration API is running",
        "timestamp": datetime.now().isoformat(),
        "features": [
            "Real-time weather data",
            "Weather forecasts",
            "Agricultural recommendations",
            "Irrigation guidance",
            "Weather alerts"
        ]
    })

@app.route('/weather/current', methods=['GET'])
def get_current_weather():
    """Get current weather data"""
    try:
        lat = request.args.get('lat', '28.6139')  # Default to Delhi
        lon = request.args.get('lon', '77.2090')
        location = request.args.get('location', 'Delhi')
        
        # For demo purposes, generate simulated weather data
        # In production, integrate with OpenWeatherMap API
        weather_data = {
            'location': location,
            'latitude': float(lat),
            'longitude': float(lon),
            'temperature': round(random.uniform(15, 35), 1),
            'humidity': round(random.uniform(30, 90), 1),
            'pressure': round(random.uniform(1000, 1020), 1),
            'wind_speed': round(random.uniform(5, 25), 1),
            'wind_direction': round(random.uniform(0, 360), 1),
            'visibility': round(random.uniform(5, 15), 1),
            'uv_index': round(random.uniform(1, 10), 1),
            'weather_condition': random.choice(['Clear', 'Clouds', 'Rain', 'Thunderstorm']),
            'weather_description': random.choice(['clear sky', 'few clouds', 'scattered clouds', 'light rain', 'moderate rain']),
            'timestamp': datetime.now().isoformat()
        }
        
        # Store in database
        conn = psycopg2.connect(**DATABASE_CONFIG)
        cursor = conn.cursor()
        
        weather_id = f"weather_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{hash(location) % 10000}"
        
        cursor.execute('''
            INSERT INTO weather_data 
            (id, location, latitude, longitude, temperature, humidity, pressure,
             wind_speed, wind_direction, visibility, uv_index, weather_condition,
             weather_description)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            weather_id,
            location,
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
            weather_data['weather_description']
        ))
        
                    conn.commit()
    except Exception as e:
        print(f"Database initialization error: {e}")
        raise e
        
        return jsonify({
            "success": True,
            "data": weather_data
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/weather/forecast', methods=['GET'])
def get_weather_forecast():
    """Get weather forecast"""
    try:
        lat = request.args.get('lat', '28.6139')
        lon = request.args.get('lon', '77.2090')
        location = request.args.get('location', 'Delhi')
        days = int(request.args.get('days', 5))
        
        forecasts = []
        for i in range(days):
            forecast_date = datetime.now() + timedelta(days=i)
            forecast = {
                'date': forecast_date.strftime('%Y-%m-%d'),
                'temperature_min': round(random.uniform(10, 25), 1),
                'temperature_max': round(random.uniform(25, 40), 1),
                'humidity': round(random.uniform(40, 80), 1),
                'pressure': round(random.uniform(1000, 1020), 1),
                'wind_speed': round(random.uniform(5, 20), 1),
                'precipitation': round(random.uniform(0, 30), 1),
                'weather_condition': random.choice(['Clear', 'Clouds', 'Rain', 'Thunderstorm']),
                'weather_description': random.choice(['clear sky', 'few clouds', 'scattered clouds', 'light rain', 'moderate rain'])
            }
            forecasts.append(forecast)
            
            # Store in database
            conn = psycopg2.connect(**DATABASE_CONFIG)
            cursor = conn.cursor()
            
            forecast_id = f"forecast_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{i}_{hash(location) % 10000}"
            
            cursor.execute('''
                INSERT INTO weather_forecasts 
                (id, location, latitude, longitude, forecast_date, temperature_min,
                 temperature_max, humidity, pressure, wind_speed, precipitation,
                 weather_condition, weather_description)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                forecast_id,
                location,
                float(lat),
                float(lon),
                forecast_date.strftime('%Y-%m-%d'),
                forecast['temperature_min'],
                forecast['temperature_max'],
                forecast['humidity'],
                forecast['pressure'],
                forecast['wind_speed'],
                forecast['precipitation'],
                forecast['weather_condition'],
                forecast['weather_description']
            ))
            
                        conn.commit()
    except Exception as e:
        print(f"Database initialization error: {e}")
        raise e
        
        return jsonify({
            "success": True,
            "data": {
                "location": location,
                "forecasts": forecasts,
                "total_days": days
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/weather/recommendations', methods=['POST'])
def get_weather_recommendations_endpoint():
    """Get agricultural recommendations based on weather"""
    try:
        data = request.get_json()
        weather_data = data.get('weather_data', {})
        
        recommendations = get_weather_recommendations(weather_data)
        impact_analysis = get_weather_impact_analysis(weather_data)
        irrigation_rec = get_irrigation_recommendations(weather_data)
        
        return jsonify({
            "success": True,
            "data": {
                "recommendations": recommendations,
                "impact_analysis": impact_analysis,
                "irrigation_recommendations": irrigation_rec
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/weather/alerts', methods=['GET'])
def get_weather_alerts():
    """Get weather alerts for agricultural activities"""
    try:
        location = request.args.get('location', 'Delhi')
        
        # Generate sample alerts based on weather conditions
        alerts = []
        
        # Check for extreme weather conditions
        if random.random() > 0.7:  # 30% chance of alert
            alert_types = [
                {
                    'alert_type': 'Heat Wave',
                    'severity': 'High',
                    'message': 'Extreme heat expected. Avoid field work during peak hours.',
                    'start_date': datetime.now().strftime('%Y-%m-%d'),
                    'end_date': (datetime.now() + timedelta(days=3)).strftime('%Y-%m-%d')
                },
                {
                    'alert_type': 'Heavy Rain',
                    'severity': 'Medium',
                    'message': 'Heavy rainfall expected. Ensure proper drainage.',
                    'start_date': datetime.now().strftime('%Y-%m-%d'),
                    'end_date': (datetime.now() + timedelta(days=2)).strftime('%Y-%m-%d')
                },
                {
                    'alert_type': 'Frost Warning',
                    'severity': 'High',
                    'message': 'Frost expected tonight. Protect sensitive crops.',
                    'start_date': datetime.now().strftime('%Y-%m-%d'),
                    'end_date': (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
                }
            ]
            
            alert = random.choice(alert_types)
            alerts.append(alert)
            
            # Store in database
            conn = psycopg2.connect(**DATABASE_CONFIG)
            cursor = conn.cursor()
            
            alert_id = f"alert_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{hash(location) % 10000}"
            
            cursor.execute('''
                INSERT INTO weather_alerts 
                (id, location, alert_type, severity, message, start_date, end_date)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                alert_id,
                location,
                alert['alert_type'],
                alert['severity'],
                alert['message'],
                alert['start_date'],
                alert['end_date']
            ))
            
                        conn.commit()
    except Exception as e:
        print(f"Database initialization error: {e}")
        raise e
        
        return jsonify({
            "success": True,
            "data": {
                "location": location,
                "alerts": alerts,
                "total_alerts": len(alerts)
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/weather/history', methods=['GET'])
def get_weather_history():
    """Get historical weather data"""
    try:
        conn = psycopg2.connect(**DATABASE_CONFIG)
        cursor = conn.cursor()
        
        location = request.args.get('location')
        days = int(request.args.get('days', 7))
        
        query = '''
            SELECT * FROM weather_data 
            WHERE timestamp >= datetime('now', '-{} days')
        '''.format(days)
        
        params = []
        if location:
            query += ' AND location = ?'
            params.append(location)
        
        query += ' ORDER BY timestamp DESC'
        
        cursor.execute(query, params)
        rows = cursor.fetchall()
        
        history = []
        for row in rows:
            history.append({
                'id': row[0],
                'location': row[1],
                'latitude': row[2],
                'longitude': row[3],
                'temperature': row[4],
                'humidity': row[5],
                'pressure': row[6],
                'wind_speed': row[7],
                'wind_direction': row[8],
                'visibility': row[9],
                'uv_index': row[10],
                'weather_condition': row[11],
                'weather_description': row[12],
                'timestamp': row[13]
            })
        
        conn.close()
        
        return jsonify({
            "success": True,
            "data": {
                "weather_history": history,
                "total_records": len(history)
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/weather/analytics', methods=['GET'])
def get_weather_analytics():
    """Get weather analytics and insights"""
    try:
        conn = psycopg2.connect(**DATABASE_CONFIG)
        cursor = conn.cursor()
        
        # Get temperature trends
        cursor.execute('''
            SELECT AVG(temperature) as avg_temp, 
                   MIN(temperature) as min_temp, 
                   MAX(temperature) as max_temp,
                   COUNT(*) as record_count
            FROM weather_data 
            WHERE timestamp >= datetime('now', '-7 days')
        ''')
        
        temp_data = cursor.fetchone()
        
        # Get humidity trends
        cursor.execute('''
            SELECT AVG(humidity) as avg_humidity, 
                   MIN(humidity) as min_humidity, 
                   MAX(humidity) as max_humidity
            FROM weather_data 
            WHERE timestamp >= datetime('now', '-7 days')
        ''')
        
        humidity_data = cursor.fetchone()
        
        # Get weather condition distribution
        cursor.execute('''
            SELECT weather_condition, COUNT(*) as count
            FROM weather_data 
            WHERE timestamp >= datetime('now', '-7 days')
            GROUP BY weather_condition
        ''')
        
        condition_data = cursor.fetchall()
        
        conn.close()
        
        return jsonify({
            "success": True,
            "data": {
                "temperature_analytics": {
                    "average": round(temp_data[0], 1) if temp_data[0] else 0,
                    "minimum": round(temp_data[1], 1) if temp_data[1] else 0,
                    "maximum": round(temp_data[2], 1) if temp_data[2] else 0,
                    "record_count": temp_data[3] if temp_data[3] else 0
                },
                "humidity_analytics": {
                    "average": round(humidity_data[0], 1) if humidity_data[0] else 0,
                    "minimum": round(humidity_data[1], 1) if humidity_data[1] else 0,
                    "maximum": round(humidity_data[2], 1) if humidity_data[2] else 0
                },
                "weather_conditions": {
                    condition[0]: condition[1] for condition in condition_data
                },
                "insights": {
                    "most_common_condition": max(condition_data, key=lambda x: x[1])[0] if condition_data else "Unknown",
                    "temperature_trend": "Stable" if temp_data and temp_data[0] else "Unknown",
                    "humidity_trend": "Stable" if humidity_data and humidity_data[0] else "Unknown"
                }
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

if __name__ == '__main__':
    print("🌤️ Weather Integration API Starting...")
    print(f"📊 Database: {DB_NAME}")
    print(f"🌍 OpenWeatherMap API: {'Configured' if OPENWEATHER_API_KEY != 'your_api_key_here' else 'Demo Mode'}")
    print("🚀 Server running on http://0.0.0.0:5005")
    print("📱 Android emulator can access via http://10.0.2.2:5005")
    app.run(debug=True, host='0.0.0.0', port=5005)
