"""
SIH 2025 Integrated AI-Based Crop Recommendation System
Comprehensive API integrating all enhanced features for SIH 2025 requirements
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import sqlite3
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import os
import logging
import requests
import threading
import time

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# API Configuration
API_ENDPOINTS = {
    'crop_recommendation': 'http://localhost:8080',
    'weather_integration': 'http://localhost:5005',
    'market_price': 'http://localhost:5004',
    'yield_prediction': 'http://localhost:5003',
    'field_management': 'http://localhost:5002',
    'satellite_soil': 'http://localhost:5006',
    'multilingual_ai': 'http://localhost:5007',
    'disease_detection': 'http://localhost:5008',
    'sustainability': 'http://localhost:5009',
    'crop_rotation': 'http://localhost:5010',
    'offline_capability': 'http://localhost:5011'
}

# Database setup
DB_NAME = 'sih_2025_integrated.db'

def init_database():
    """Initialize the integrated database"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    # User sessions table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_sessions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            session_data TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Integrated recommendations table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS integrated_recommendations (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            location TEXT NOT NULL,
            soil_data TEXT NOT NULL,
            weather_data TEXT NOT NULL,
            market_data TEXT NOT NULL,
            crop_recommendation TEXT NOT NULL,
            sustainability_score REAL NOT NULL,
            rotation_plan TEXT,
            disease_risks TEXT,
            offline_available BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # API health status table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS api_health_status (
            api_name TEXT PRIMARY KEY,
            status TEXT NOT NULL,
            last_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            response_time REAL,
            error_message TEXT
        )
    ''')
    
    conn.commit()
    conn.close()

# Initialize database
init_database()

def check_api_health(api_name: str, endpoint: str) -> Dict:
    """Check health of individual API"""
    try:
        start_time = time.time()
        response = requests.get(f"{endpoint}/health", timeout=5)
        response_time = time.time() - start_time
        
        if response.status_code == 200:
            return {
                'status': 'healthy',
                'response_time': response_time,
                'last_check': datetime.now().isoformat()
            }
        else:
            return {
                'status': 'unhealthy',
                'response_time': response_time,
                'error': f"HTTP {response.status_code}",
                'last_check': datetime.now().isoformat()
            }
    except Exception as e:
        return {
            'status': 'unhealthy',
            'response_time': None,
            'error': str(e),
            'last_check': datetime.now().isoformat()
        }

def update_api_health_status():
    """Update health status of all APIs"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    for api_name, endpoint in API_ENDPOINTS.items():
        health_status = check_api_health(api_name, endpoint)
        
        cursor.execute('''
            INSERT OR REPLACE INTO api_health_status 
            (api_name, status, last_check, response_time, error_message)
            VALUES (?, ?, ?, ?, ?)
        ''', (
            api_name,
            health_status['status'],
            health_status['last_check'],
            health_status.get('response_time'),
            health_status.get('error')
        ))
    
    conn.commit()
    conn.close()

def get_comprehensive_crop_recommendation(user_data: Dict) -> Dict:
    """Get comprehensive crop recommendation using all available APIs"""
    try:
        location = user_data.get('location', {})
        soil_data = user_data.get('soil_data', {})
        weather_data = user_data.get('weather_data', {})
        market_preferences = user_data.get('market_preferences', {})
        
        # Initialize recommendation data
        recommendation_data = {
            'basic_recommendation': None,
            'weather_analysis': None,
            'market_analysis': None,
            'sustainability_score': None,
            'rotation_plan': None,
            'disease_risks': None,
            'yield_prediction': None,
            'offline_available': False
        }
        
        # 1. Get basic crop recommendation
        try:
            crop_response = requests.post(f"{API_ENDPOINTS['crop_recommendation']}/recommend", 
                                        json=soil_data, timeout=10)
            if crop_response.status_code == 200:
                recommendation_data['basic_recommendation'] = crop_response.json()
        except Exception as e:
            logger.warning(f"Crop recommendation API error: {str(e)}")
        
        # 2. Get weather analysis
        try:
            weather_response = requests.get(f"{API_ENDPOINTS['weather_integration']}/weather/current",
                                          params=location, timeout=10)
            if weather_response.status_code == 200:
                recommendation_data['weather_analysis'] = weather_response.json()
        except Exception as e:
            logger.warning(f"Weather API error: {str(e)}")
        
        # 3. Get market analysis
        try:
            if recommendation_data['basic_recommendation']:
                crop_name = recommendation_data['basic_recommendation'].get('data', {}).get('recommended_crop')
                if crop_name:
                    market_response = requests.get(f"{API_ENDPOINTS['market_price']}/price/current",
                                                 params={'crop': crop_name}, timeout=10)
                    if market_response.status_code == 200:
                        recommendation_data['market_analysis'] = market_response.json()
        except Exception as e:
            logger.warning(f"Market price API error: {str(e)}")
        
        # 4. Get sustainability score
        try:
            sustainability_data = {
                'crop_data': {'crop_type': recommendation_data['basic_recommendation'].get('data', {}).get('recommended_crop', 'Rice')},
                'farm_conditions': {'farm_area': user_data.get('farm_area', 1.0)}
            }
            sustainability_response = requests.post(f"{API_ENDPOINTS['sustainability']}/assess/sustainability",
                                                  json=sustainability_data, timeout=10)
            if sustainability_response.status_code == 200:
                recommendation_data['sustainability_score'] = sustainability_response.json()
        except Exception as e:
            logger.warning(f"Sustainability API error: {str(e)}")
        
        # 5. Get crop rotation plan
        try:
            rotation_data = {
                'current_crop': recommendation_data['basic_recommendation'].get('data', {}).get('recommended_crop', 'Rice'),
                'soil_conditions': soil_data,
                'duration_years': 3
            }
            rotation_response = requests.post(f"{API_ENDPOINTS['crop_rotation']}/rotation/plan",
                                            json=rotation_data, timeout=10)
            if rotation_response.status_code == 200:
                recommendation_data['rotation_plan'] = rotation_response.json()
        except Exception as e:
            logger.warning(f"Crop rotation API error: {str(e)}")
        
        # 6. Get yield prediction
        try:
            if recommendation_data['basic_recommendation']:
                yield_data = {
                    'crop_name': recommendation_data['basic_recommendation'].get('data', {}).get('recommended_crop'),
                    'area_hectares': user_data.get('farm_area', 1.0),
                    'soil_conditions': soil_data,
                    'weather_conditions': weather_data
                }
                yield_response = requests.post(f"{API_ENDPOINTS['yield_prediction']}/predict",
                                             json=yield_data, timeout=10)
                if yield_response.status_code == 200:
                    recommendation_data['yield_prediction'] = yield_response.json()
        except Exception as e:
            logger.warning(f"Yield prediction API error: {str(e)}")
        
        # 7. Check offline availability
        try:
            offline_response = requests.get(f"{API_ENDPOINTS['offline_capability']}/offline/status", timeout=5)
            if offline_response.status_code == 200:
                offline_data = offline_response.json()
                recommendation_data['offline_available'] = offline_data.get('data', {}).get('offline_mode', False)
        except Exception as e:
            logger.warning(f"Offline capability API error: {str(e)}")
        
        return recommendation_data
        
    except Exception as e:
        logger.error(f"Comprehensive recommendation error: {str(e)}")
        return {
            'error': str(e),
            'basic_recommendation': None,
            'weather_analysis': None,
            'market_analysis': None,
            'sustainability_score': None,
            'rotation_plan': None,
            'disease_risks': None,
            'yield_prediction': None,
            'offline_available': False
        }

def get_multilingual_support(message: str, language: str = 'auto') -> Dict:
    """Get multilingual support for user queries"""
    try:
        chat_data = {
            'message': message,
            'language': language,
            'user_id': 'integrated_user'
        }
        
        response = requests.post(f"{API_ENDPOINTS['multilingual_ai']}/chat",
                               json=chat_data, timeout=10)
        
        if response.status_code == 200:
            return response.json()
        else:
            return {
                'success': False,
                'error': f"Multilingual API error: {response.status_code}"
            }
    except Exception as e:
        logger.error(f"Multilingual support error: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }

def analyze_disease_from_image(image_data: str, crop_type: str) -> Dict:
    """Analyze disease from image using AI detection"""
    try:
        disease_data = {
            'crop_type': crop_type,
            'image_data': image_data,
            'user_id': 'integrated_user'
        }
        
        response = requests.post(f"{API_ENDPOINTS['disease_detection']}/detect/analyze",
                               json=disease_data, timeout=15)
        
        if response.status_code == 200:
            return response.json()
        else:
            return {
                'success': False,
                'error': f"Disease detection API error: {response.status_code}"
            }
    except Exception as e:
        logger.error(f"Disease detection error: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }

def get_satellite_soil_data(location: Dict) -> Dict:
    """Get satellite-based soil data"""
    try:
        response = requests.get(f"{API_ENDPOINTS['satellite_soil']}/soil/current",
                              params=location, timeout=10)
        
        if response.status_code == 200:
            return response.json()
        else:
            return {
                'success': False,
                'error': f"Satellite soil API error: {response.status_code}"
            }
    except Exception as e:
        logger.error(f"Satellite soil data error: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }

def store_integrated_recommendation(user_id: str, recommendation_data: Dict):
    """Store integrated recommendation in database"""
    try:
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        recommendation_id = f"integrated_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{hash(user_id) % 10000}"
        
        cursor.execute('''
            INSERT INTO integrated_recommendations 
            (id, user_id, location, soil_data, weather_data, market_data,
             crop_recommendation, sustainability_score, rotation_plan, disease_risks,
             offline_available)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            recommendation_id, user_id,
            json.dumps(recommendation_data.get('location', {})),
            json.dumps(recommendation_data.get('soil_data', {})),
            json.dumps(recommendation_data.get('weather_data', {})),
            json.dumps(recommendation_data.get('market_analysis', {})),
            json.dumps(recommendation_data.get('basic_recommendation', {})),
            recommendation_data.get('sustainability_score', {}).get('data', {}).get('sustainability_assessment', {}).get('overall_score', 0),
            json.dumps(recommendation_data.get('rotation_plan', {})),
            json.dumps(recommendation_data.get('disease_risks', {})),
            recommendation_data.get('offline_available', False)
        ))
        
        conn.commit()
        conn.close()
        
    except Exception as e:
        logger.error(f"Storage error: {str(e)}")

# API Endpoints

@app.route('/health', methods=['GET'])
def health_check():
    """Comprehensive health check for all integrated APIs"""
    try:
        # Update API health status
        update_api_health_status()
        
        # Get health status from database
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        cursor.execute('SELECT * FROM api_health_status')
        health_data = cursor.fetchall()
        
        conn.close()
        
        # Calculate overall health
        healthy_apis = sum(1 for row in health_data if row[1] == 'healthy')
        total_apis = len(health_data)
        overall_health = 'healthy' if healthy_apis == total_apis else 'degraded' if healthy_apis > total_apis // 2 else 'unhealthy'
        
        return jsonify({
            "success": True,
            "message": "SIH 2025 Integrated API is running",
            "timestamp": datetime.now().isoformat(),
            "overall_health": overall_health,
            "api_status": {
                row[0]: {
                    'status': row[1],
                    'last_check': row[2],
                    'response_time': row[3],
                    'error': row[4]
                } for row in health_data
            },
            "features": [
                "AI-based crop recommendations",
                "Satellite soil data integration",
                "Multilingual voice and chat support",
                "Advanced disease detection",
                "Sustainability scoring",
                "Crop rotation planning",
                "Offline capability",
                "Real-time weather integration",
                "Market price analysis",
                "Yield prediction"
            ]
        })
    
    except Exception as e:
        logger.error(f"Health check error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/recommend/comprehensive', methods=['POST'])
def comprehensive_recommendation():
    """Get comprehensive crop recommendation using all available data"""
    try:
        data = request.get_json()
        
        user_id = data.get('user_id', 'anonymous')
        location = data.get('location', {})
        soil_data = data.get('soil_data', {})
        weather_data = data.get('weather_data', {})
        market_preferences = data.get('market_preferences', {})
        farm_area = data.get('farm_area', 1.0)
        
        # Prepare user data
        user_data = {
            'location': location,
            'soil_data': soil_data,
            'weather_data': weather_data,
            'market_preferences': market_preferences,
            'farm_area': farm_area
        }
        
        # Get comprehensive recommendation
        recommendation_data = get_comprehensive_crop_recommendation(user_data)
        
        # Store recommendation
        store_integrated_recommendation(user_id, recommendation_data)
        
        # Generate summary
        summary = generate_recommendation_summary(recommendation_data)
        
        return jsonify({
            "success": True,
            "data": {
                "recommendation_summary": summary,
                "detailed_analysis": recommendation_data,
                "timestamp": datetime.now().isoformat(),
                "user_id": user_id
            }
        })
    
    except Exception as e:
        logger.error(f"Comprehensive recommendation error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/chat/multilingual', methods=['POST'])
def multilingual_chat():
    """Handle multilingual chat queries"""
    try:
        data = request.get_json()
        
        message = data.get('message', '')
        language = data.get('language', 'auto')
        
        if not message:
            return jsonify({
                "success": False,
                "error": "Message is required"
            }), 400
        
        # Get multilingual support
        chat_response = get_multilingual_support(message, language)
        
        return jsonify(chat_response)
    
    except Exception as e:
        logger.error(f"Multilingual chat error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/analyze/disease', methods=['POST'])
def analyze_disease():
    """Analyze plant disease from image"""
    try:
        data = request.get_json()
        
        image_data = data.get('image_data', '')
        crop_type = data.get('crop_type', 'Rice')
        
        if not image_data:
            return jsonify({
                "success": False,
                "error": "Image data is required"
            }), 400
        
        # Analyze disease
        disease_analysis = analyze_disease_from_image(image_data, crop_type)
        
        return jsonify(disease_analysis)
    
    except Exception as e:
        logger.error(f"Disease analysis error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/soil/satellite', methods=['GET'])
def get_satellite_soil():
    """Get satellite-based soil data"""
    try:
        location = {
            'lat': request.args.get('lat', '28.6139'),
            'lon': request.args.get('lon', '77.2090'),
            'location': request.args.get('location', 'Delhi')
        }
        
        soil_data = get_satellite_soil_data(location)
        
        return jsonify(soil_data)
    
    except Exception as e:
        logger.error(f"Satellite soil data error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/offline/sync', methods=['POST'])
def sync_offline_data():
    """Sync offline data when connection is available"""
    try:
        response = requests.post(f"{API_ENDPOINTS['offline_capability']}/offline/sync", timeout=30)
        
        if response.status_code == 200:
            return response.json()
        else:
            return jsonify({
                "success": False,
                "error": f"Offline sync error: {response.status_code}"
            }), 500
    
    except Exception as e:
        logger.error(f"Offline sync error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

def generate_recommendation_summary(recommendation_data: Dict) -> Dict:
    """Generate a summary of the comprehensive recommendation"""
    try:
        summary = {
            'primary_recommendation': 'No recommendation available',
            'confidence_score': 0.0,
            'key_benefits': [],
            'risks_and_considerations': [],
            'next_steps': [],
            'sustainability_rating': 'Unknown',
            'market_outlook': 'Unknown',
            'offline_available': False
        }
        
        # Extract primary recommendation
        basic_rec = recommendation_data.get('basic_recommendation', {})
        if basic_rec and basic_rec.get('success'):
            rec_data = basic_rec.get('data', {})
            summary['primary_recommendation'] = rec_data.get('recommended_crop', 'Unknown')
            summary['confidence_score'] = rec_data.get('confidence', 0.0)
        
        # Extract sustainability rating
        sustainability = recommendation_data.get('sustainability_score', {})
        if sustainability and sustainability.get('success'):
            sus_data = sustainability.get('data', {})
            sus_assessment = sus_data.get('sustainability_assessment', {})
            summary['sustainability_rating'] = sus_assessment.get('rating', 'Unknown')
        
        # Extract market outlook
        market = recommendation_data.get('market_analysis', {})
        if market and market.get('success'):
            market_data = market.get('data', {})
            summary['market_outlook'] = 'Positive' if market_data.get('current_price', 0) > 0 else 'Unknown'
        
        # Extract offline availability
        summary['offline_available'] = recommendation_data.get('offline_available', False)
        
        # Generate key benefits
        if summary['primary_recommendation'] != 'No recommendation available':
            summary['key_benefits'].append(f"Recommended crop: {summary['primary_recommendation']}")
            summary['key_benefits'].append(f"Confidence: {summary['confidence_score']:.1%}")
        
        if summary['sustainability_rating'] != 'Unknown':
            summary['key_benefits'].append(f"Sustainability rating: {summary['sustainability_rating']}")
        
        if summary['market_outlook'] != 'Unknown':
            summary['key_benefits'].append(f"Market outlook: {summary['market_outlook']}")
        
        # Generate next steps
        summary['next_steps'] = [
            "Monitor soil conditions regularly",
            "Check weather forecasts",
            "Plan crop rotation strategy",
            "Monitor for diseases and pests",
            "Track market prices"
        ]
        
        if summary['offline_available']:
            summary['next_steps'].append("Use offline mode for low-connectivity areas")
        
        return summary
        
    except Exception as e:
        logger.error(f"Summary generation error: {str(e)}")
        return {
            'primary_recommendation': 'Error generating recommendation',
            'confidence_score': 0.0,
            'key_benefits': [],
            'risks_and_considerations': [],
            'next_steps': ['Contact support for assistance'],
            'sustainability_rating': 'Unknown',
            'market_outlook': 'Unknown',
            'offline_available': False
        }

# Background task to update API health status
def background_health_check():
    """Background task to check API health"""
    while True:
        try:
            update_api_health_status()
            time.sleep(300)  # Check every 5 minutes
        except Exception as e:
            logger.error(f"Background health check error: {str(e)}")
            time.sleep(60)  # Wait 1 minute on error

# Start background health check
health_thread = threading.Thread(target=background_health_check, daemon=True)
health_thread.start()

if __name__ == '__main__':
    print("🚀 SIH 2025 Integrated AI-Based Crop Recommendation System Starting...")
    print(f"📊 Database: {DB_NAME}")
    print(f"🔗 Integrated APIs: {len(API_ENDPOINTS)}")
    print("🌾 Features:")
    print("  ✅ AI-based crop recommendations")
    print("  ✅ Satellite soil data integration")
    print("  ✅ Multilingual voice and chat support")
    print("  ✅ Advanced disease detection")
    print("  ✅ Sustainability scoring")
    print("  ✅ Crop rotation planning")
    print("  ✅ Offline capability")
    print("  ✅ Real-time weather integration")
    print("  ✅ Market price analysis")
    print("  ✅ Yield prediction")
    print("🚀 Server running on http://0.0.0.0:5012")
    print("📱 Android emulator can access via http://10.0.2.2:5012")
    app.run(debug=True, host='0.0.0.0', port=5012)
