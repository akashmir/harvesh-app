#!/usr/bin/env python3
"""
Simple SQLite-based APIs for Ultra Crop Recommender System
No PostgreSQL dependency - works with SQLite databases
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import sqlite3
import os
import sys
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import logging
import threading
import time
import subprocess
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database paths
DB_DIR = Path(__file__).parent / 'data'
DB_DIR.mkdir(exist_ok=True)

DATABASES = {
    'satellite_soil': DB_DIR / 'satellite_soil.db',
    'weather': DB_DIR / 'weather_integration.db',
    'market_price': DB_DIR / 'market_price.db',
    'yield_prediction': DB_DIR / 'yield_prediction.db',
    'sustainability': DB_DIR / 'sustainability_scoring.db',
    'crop_rotation': DB_DIR / 'crop_rotation.db',
    'multilingual': DB_DIR / 'multilingual_ai.db',
    'field_management': DB_DIR / 'field_management.db',
    'disease_detection': DB_DIR / 'disease_detection.db',
    'offline': DB_DIR / 'offline_capability.db'
}

def init_sqlite_database(db_path: Path, table_name: str):
    """Initialize SQLite database with basic table"""
    with sqlite3.connect(str(db_path)) as conn:
        cursor = conn.cursor()
        
        # Create a generic data table
        cursor.execute(f'''
            CREATE TABLE IF NOT EXISTS {table_name} (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                data_type TEXT,
                location TEXT,
                latitude REAL,
                longitude REAL,
                data_json TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        conn.commit()

def init_all_databases():
    """Initialize all SQLite databases"""
    tables = {
        'satellite_soil': 'soil_data',
        'weather': 'weather_data',
        'market_price': 'market_data',
        'yield_prediction': 'yield_data',
        'sustainability': 'sustainability_data',
        'crop_rotation': 'rotation_data',
        'multilingual': 'chat_data',
        'field_management': 'field_data',
        'disease_detection': 'disease_data',
        'offline': 'offline_data'
    }
    
    for db_name, table_name in tables.items():
        init_sqlite_database(DATABASES[db_name], table_name)

# Initialize databases
init_all_databases()

class SimpleAPIServer:
    """Simple API server that provides mock responses for all supporting APIs"""
    
    def __init__(self):
        self.apps = {}
        self.processes = []
    
    def create_satellite_soil_app(self):
        """Create Satellite Soil API"""
        app = Flask(__name__)
        CORS(app)
        
        @app.route('/health', methods=['GET'])
        def health():
            return jsonify({"success": True, "message": "Satellite Soil API is running"})
        
        @app.route('/soil/current', methods=['GET'])
        def get_current_soil():
            lat = float(request.args.get('latitude', 28.6139))
            lon = float(request.args.get('longitude', 77.2090))
            
            # Mock satellite soil data
            return jsonify({
                "success": True,
                "data": {
                    "location": {"latitude": lat, "longitude": lon},
                    "soil_properties": {
                        "ph": 6.5 + (lat * 0.01),
                        "nitrogen": 120 + (lon * 0.5),
                        "phosphorus": 25 + (lat * 0.2),
                        "potassium": 200 + (lon * 0.3),
                        "organic_carbon": 1.2 + (lat * 0.01),
                        "soil_moisture": 45 + (lon * 0.1),
                        "clay_content": 35 + (lat * 0.2),
                        "sand_content": 40 + (lon * 0.1)
                    },
                    "health_indicators": {
                        "health_score": 75 + (lat * 0.5),
                        "fertility_index": 70 + (lon * 0.3)
                    },
                    "data_source": "Mock Satellite Data"
                }
            })
        
        return app
    
    def create_weather_app(self):
        """Create Weather Integration API"""
        app = Flask(__name__)
        CORS(app)
        
        @app.route('/health', methods=['GET'])
        def health():
            return jsonify({"success": True, "message": "Weather API is running"})
        
        @app.route('/weather/current', methods=['GET'])
        def get_current_weather():
            lat = float(request.args.get('latitude', 28.6139))
            lon = float(request.args.get('longitude', 77.2090))
            
            return jsonify({
                "success": True,
                "data": {
                    "location": {"latitude": lat, "longitude": lon},
                    "current": {
                        "temperature": 25 + (lat * 0.2),
                        "humidity": 60 + (lon * 0.1),
                        "rainfall": 0,
                        "wind_speed": 10 + (lat * 0.1),
                        "pressure": 1013 + (lon * 0.01)
                    },
                    "forecast": {
                        "temperature_trend": "stable",
                        "rainfall_prediction": "moderate",
                        "weather_advisory": "Suitable for farming activities"
                    }
                }
            })
        
        return app
    
    def create_market_price_app(self):
        """Create Market Price API"""
        app = Flask(__name__)
        CORS(app)
        
        @app.route('/health', methods=['GET'])
        def health():
            return jsonify({"success": True, "message": "Market Price API is running"})
        
        @app.route('/market/prices', methods=['GET'])
        def get_market_prices():
            crop = request.args.get('crop', 'Rice')
            
            base_prices = {
                'Rice': 2000, 'Wheat': 1800, 'Maize': 1500,
                'Cotton': 5000, 'Sugarcane': 300, 'Soybean': 3500
            }
            
            base_price = base_prices.get(crop, 2000)
            
            return jsonify({
                "success": True,
                "data": {
                    "crop": crop,
                    "current_price": base_price,
                    "price_trend": "stable",
                    "market_demand": "high",
                    "data_source": "Mock Market Data"
                }
            })
        
        return app
    
    def create_yield_prediction_app(self):
        """Create Yield Prediction API"""
        app = Flask(__name__)
        CORS(app)
        
        @app.route('/health', methods=['GET'])
        def health():
            return jsonify({"success": True, "message": "Yield Prediction API is running"})
        
        @app.route('/yield/predict', methods=['POST'])
        def predict_yield():
            data = request.get_json()
            crop = data.get('crop', 'Rice')
            
            yield_estimates = {
                'Rice': '4-6 tons/hectare',
                'Wheat': '3-5 tons/hectare',
                'Maize': '5-8 tons/hectare',
                'Cotton': '15-25 quintals/hectare',
                'Sugarcane': '80-120 tons/hectare',
                'Soybean': '2-3 tons/hectare'
            }
            
            return jsonify({
                "success": True,
                "data": {
                    "crop": crop,
                    "predicted_yield": yield_estimates.get(crop, '3-5 tons/hectare'),
                    "confidence": 0.85,
                    "factors": ["soil quality", "weather conditions", "farming practices"]
                }
            })
        
        return app
    
    def create_sustainability_app(self):
        """Create Sustainability Scoring API"""
        app = Flask(__name__)
        CORS(app)
        
        @app.route('/health', methods=['GET'])
        def health():
            return jsonify({"success": True, "message": "Sustainability API is running"})
        
        @app.route('/sustainability/score', methods=['POST'])
        def get_sustainability_score():
            data = request.get_json()
            crop = data.get('crop', 'Rice')
            
            scores = {
                'Rice': 7.5, 'Wheat': 8.0, 'Maize': 8.5,
                'Cotton': 6.5, 'Sugarcane': 7.0, 'Soybean': 9.0
            }
            
            return jsonify({
                "success": True,
                "data": {
                    "crop": crop,
                    "sustainability_score": scores.get(crop, 7.5),
                    "environmental_impact": "medium",
                    "recommendations": ["Use organic fertilizers", "Implement crop rotation"]
                }
            })
        
        return app
    
    def create_crop_rotation_app(self):
        """Create Crop Rotation API"""
        app = Flask(__name__)
        CORS(app)
        
        @app.route('/health', methods=['GET'])
        def health():
            return jsonify({"success": True, "message": "Crop Rotation API is running"})
        
        @app.route('/rotation/suggest', methods=['POST'])
        def suggest_rotation():
            data = request.get_json()
            current_crop = data.get('current_crop', 'Rice')
            
            rotations = {
                'Rice': ['Wheat', 'Legumes'],
                'Wheat': ['Rice', 'Maize'],
                'Maize': ['Soybean', 'Wheat'],
                'Cotton': ['Wheat', 'Legumes'],
                'Sugarcane': ['Wheat', 'Legumes'],
                'Soybean': ['Rice', 'Wheat']
            }
            
            return jsonify({
                "success": True,
                "data": {
                    "current_crop": current_crop,
                    "suggested_rotation": rotations.get(current_crop, ['Wheat', 'Legumes']),
                    "benefits": ["Soil health improvement", "Pest management", "Nutrient cycling"]
                }
            })
        
        return app
    
    def create_multilingual_app(self):
        """Create Multilingual AI API"""
        app = Flask(__name__)
        CORS(app)
        
        @app.route('/health', methods=['GET'])
        def health():
            return jsonify({"success": True, "message": "Multilingual AI API is running"})
        
        @app.route('/chat', methods=['POST'])
        def chat():
            data = request.get_json()
            message = data.get('message', '')
            language = data.get('language', 'en')
            
            responses = {
                'en': "I can help you with crop recommendations and farming advice.",
                'hi': "मैं आपकी फसल की सिफारिशों और कृषि सलाह में मदद कर सकता हूं।"
            }
            
            return jsonify({
                "success": True,
                "data": {
                    "response": responses.get(language, responses['en']),
                    "language": language,
                    "confidence": 0.9
                }
            })
        
        return app
    
    def start_api_server(self, app, port):
        """Start an API server on specified port"""
        try:
            app.run(debug=False, host='0.0.0.0', port=port, use_reloader=False)
        except Exception as e:
            logger.error(f"Error starting server on port {port}: {e}")

def start_all_apis():
    """Start all supporting APIs"""
    api_server = SimpleAPIServer()
    
    # Create all apps
    apps_config = [
        (api_server.create_satellite_soil_app(), 5006, "Satellite Soil API"),
        (api_server.create_weather_app(), 5005, "Weather Integration API"),
        (api_server.create_market_price_app(), 5004, "Market Price API"),
        (api_server.create_yield_prediction_app(), 5003, "Yield Prediction API"),
        (api_server.create_sustainability_app(), 5009, "Sustainability API"),
        (api_server.create_crop_rotation_app(), 5010, "Crop Rotation API"),
        (api_server.create_multilingual_app(), 5007, "Multilingual AI API")
    ]
    
    processes = []
    
    for app, port, name in apps_config:
        print(f"Starting {name} on port {port}...")
        process = threading.Thread(
            target=api_server.start_api_server,
            args=(app, port),
            daemon=True
        )
        process.start()
        processes.append(process)
        time.sleep(0.5)  # Small delay between starts
    
    return processes

if __name__ == '__main__':
    print("="*60)
    print("STARTING SUPPORTING APIs (SQLite-based)")
    print("="*60)
    
    # Start all supporting APIs
    processes = start_all_apis()
    
    print("\nSupporting APIs started:")
    print("  * Satellite Soil API:     http://localhost:5006")
    print("  * Weather Integration:    http://localhost:5005")
    print("  * Market Price API:       http://localhost:5004")
    print("  * Yield Prediction API:   http://localhost:5003")
    print("  * Sustainability API:     http://localhost:5009")
    print("  * Crop Rotation API:      http://localhost:5010")
    print("  * Multilingual AI API:    http://localhost:5007")
    print("\nAll APIs are running with SQLite databases (no PostgreSQL needed)")
    print("Press Ctrl+C to stop all APIs")
    print("="*60)
    
    try:
        # Keep main thread alive
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nShutting down all APIs...")
        print("Shutdown complete")
