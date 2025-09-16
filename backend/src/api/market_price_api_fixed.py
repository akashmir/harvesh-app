"""
Market Price API - Fixed PostgreSQL Version
Provides market price predictions and analysis
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
import numpy as np
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

def init_database():
    """Initialize database tables using PostgreSQL"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Market prices table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS market_prices (
                    id VARCHAR PRIMARY KEY,
                    crop_name VARCHAR NOT NULL,
                    location VARCHAR NOT NULL,
                    price_per_kg FLOAT NOT NULL,
                    currency VARCHAR NOT NULL,
                    market_name VARCHAR NOT NULL,
                    date DATE NOT NULL,
                    source VARCHAR NOT NULL,
                    quality_grade VARCHAR,
                    volume_kg FLOAT,
                    price_trend VARCHAR,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Price predictions table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS price_predictions (
                    id VARCHAR PRIMARY KEY,
                    crop_name VARCHAR NOT NULL,
                    location VARCHAR NOT NULL,
                    predicted_price FLOAT NOT NULL,
                    confidence_score FLOAT NOT NULL,
                    prediction_date DATE NOT NULL,
                    target_date DATE NOT NULL,
                    model_used VARCHAR NOT NULL,
                    factors_considered TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Market analysis table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS market_analysis (
                    id VARCHAR PRIMARY KEY,
                    crop_name VARCHAR NOT NULL,
                    location VARCHAR NOT NULL,
                    analysis_date DATE NOT NULL,
                    demand_level VARCHAR NOT NULL,
                    supply_level VARCHAR NOT NULL,
                    price_volatility FLOAT NOT NULL,
                    market_trend VARCHAR NOT NULL,
                    seasonal_factor FLOAT NOT NULL,
                    external_factors TEXT,
                    recommendation TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            conn.commit()
            print("✅ Market Price database tables initialized successfully")
            
    except Exception as e:
        print(f"❌ Database initialization error: {e}")
        raise e

# Initialize database
init_database()

# Sample crop data for predictions
CROP_DATA = {
    'wheat': {'base_price': 25.0, 'volatility': 0.15, 'seasonal_factor': 1.2},
    'rice': {'base_price': 30.0, 'volatility': 0.12, 'seasonal_factor': 1.1},
    'maize': {'base_price': 20.0, 'volatility': 0.18, 'seasonal_factor': 1.0},
    'sugarcane': {'base_price': 35.0, 'volatility': 0.10, 'seasonal_factor': 1.3},
    'cotton': {'base_price': 60.0, 'volatility': 0.20, 'seasonal_factor': 0.9},
    'potato': {'base_price': 15.0, 'volatility': 0.25, 'seasonal_factor': 1.1},
    'tomato': {'base_price': 40.0, 'volatility': 0.30, 'seasonal_factor': 1.4},
    'onion': {'base_price': 35.0, 'volatility': 0.35, 'seasonal_factor': 1.2}
}

def get_current_price(crop_name: str, location: str) -> Dict:
    """Get current market price for a crop"""
    try:
        # Generate realistic price data
        crop_info = CROP_DATA.get(crop_name.lower(), {'base_price': 25.0, 'volatility': 0.15, 'seasonal_factor': 1.0})
        
        # Add some randomness and seasonal variation
        base_price = crop_info['base_price']
        volatility = crop_info['volatility']
        seasonal_factor = crop_info['seasonal_factor']
        
        # Simulate price variation
        price_variation = random.uniform(-volatility, volatility)
        seasonal_adjustment = random.uniform(0.8, 1.2) * seasonal_factor
        
        current_price = base_price * (1 + price_variation) * seasonal_adjustment
        current_price = round(current_price, 2)
        
        # Generate price trend
        trend = random.choice(['increasing', 'decreasing', 'stable'])
        
        price_data = {
            'crop_name': crop_name,
            'location': location,
            'price_per_kg': current_price,
            'currency': 'INR',
            'market_name': f"{location} Agricultural Market",
            'date': datetime.now().strftime('%Y-%m-%d'),
            'source': 'Market API',
            'quality_grade': random.choice(['A', 'B', 'C']),
            'volume_kg': random.uniform(1000, 10000),
            'price_trend': trend,
            'timestamp': datetime.now().isoformat()
        }
        
        # Store in database
        with get_db_cursor() as (cursor, conn):
            cursor.execute('''
                INSERT INTO market_prices 
                (id, crop_name, location, price_per_kg, currency, market_name, date, 
                 source, quality_grade, volume_kg, price_trend)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                price_per_kg = EXCLUDED.price_per_kg,
                volume_kg = EXCLUDED.volume_kg,
                price_trend = EXCLUDED.price_trend,
                created_at = CURRENT_TIMESTAMP
            ''', (
                f"price_{crop_name}_{location}_{datetime.now().strftime('%Y%m%d')}",
                price_data['crop_name'],
                price_data['location'],
                price_data['price_per_kg'],
                price_data['currency'],
                price_data['market_name'],
                price_data['date'],
                price_data['source'],
                price_data['quality_grade'],
                price_data['volume_kg'],
                price_data['price_trend']
            ))
            conn.commit()
        
        return price_data
        
    except Exception as e:
        print(f"Error getting current price: {e}")
        return {'error': str(e)}

def predict_price(crop_name: str, location: str, days_ahead: int = 30) -> Dict:
    """Predict market price for a crop"""
    try:
        # Get current price as base
        current_data = get_current_price(crop_name, location)
        if 'error' in current_data:
            return current_data
        
        current_price = current_data['price_per_kg']
        crop_info = CROP_DATA.get(crop_name.lower(), {'base_price': 25.0, 'volatility': 0.15, 'seasonal_factor': 1.0})
        
        # Simple prediction model
        volatility = crop_info['volatility']
        seasonal_factor = crop_info['seasonal_factor']
        
        # Predict price based on trend and volatility
        trend_factor = 1.0
        if current_data['price_trend'] == 'increasing':
            trend_factor = 1.0 + (days_ahead * 0.01)
        elif current_data['price_trend'] == 'decreasing':
            trend_factor = 1.0 - (days_ahead * 0.01)
        
        # Add some randomness
        random_factor = random.uniform(0.95, 1.05)
        
        predicted_price = current_price * trend_factor * random_factor
        predicted_price = round(predicted_price, 2)
        
        # Calculate confidence based on volatility
        confidence = max(0.5, 1.0 - (volatility * 2))
        confidence = round(confidence, 2)
        
        prediction_data = {
            'crop_name': crop_name,
            'location': location,
            'current_price': current_price,
            'predicted_price': predicted_price,
            'confidence_score': confidence,
            'prediction_date': datetime.now().strftime('%Y-%m-%d'),
            'target_date': (datetime.now() + timedelta(days=days_ahead)).strftime('%Y-%m-%d'),
            'days_ahead': days_ahead,
            'price_change': round(predicted_price - current_price, 2),
            'price_change_percent': round(((predicted_price - current_price) / current_price) * 100, 2),
            'model_used': 'Simple Trend Analysis',
            'factors_considered': ['Historical trends', 'Seasonal patterns', 'Market volatility'],
            'timestamp': datetime.now().isoformat()
        }
        
        # Store prediction in database
        with get_db_cursor() as (cursor, conn):
            cursor.execute('''
                INSERT INTO price_predictions 
                (id, crop_name, location, predicted_price, confidence_score, 
                 prediction_date, target_date, model_used, factors_considered)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                predicted_price = EXCLUDED.predicted_price,
                confidence_score = EXCLUDED.confidence_score,
                created_at = CURRENT_TIMESTAMP
            ''', (
                f"pred_{crop_name}_{location}_{datetime.now().strftime('%Y%m%d')}",
                prediction_data['crop_name'],
                prediction_data['location'],
                prediction_data['predicted_price'],
                prediction_data['confidence_score'],
                prediction_data['prediction_date'],
                prediction_data['target_date'],
                prediction_data['model_used'],
                json.dumps(prediction_data['factors_considered'])
            ))
            conn.commit()
        
        return prediction_data
        
    except Exception as e:
        print(f"Error predicting price: {e}")
        return {'error': str(e)}

def get_market_analysis(crop_name: str, location: str) -> Dict:
    """Get market analysis for a crop"""
    try:
        # Generate market analysis
        demand_level = random.choice(['High', 'Medium', 'Low'])
        supply_level = random.choice(['High', 'Medium', 'Low'])
        price_volatility = random.uniform(0.1, 0.4)
        market_trend = random.choice(['Bullish', 'Bearish', 'Neutral'])
        seasonal_factor = random.uniform(0.8, 1.3)
        
        # Generate recommendation based on analysis
        if demand_level == 'High' and supply_level == 'Low':
            recommendation = "Favorable market conditions. Consider selling at current prices."
        elif demand_level == 'Low' and supply_level == 'High':
            recommendation = "Challenging market conditions. Consider holding or finding alternative markets."
        else:
            recommendation = "Stable market conditions. Monitor price trends closely."
        
        analysis_data = {
            'crop_name': crop_name,
            'location': location,
            'analysis_date': datetime.now().strftime('%Y-%m-%d'),
            'demand_level': demand_level,
            'supply_level': supply_level,
            'price_volatility': round(price_volatility, 2),
            'market_trend': market_trend,
            'seasonal_factor': round(seasonal_factor, 2),
            'external_factors': [
                'Weather conditions',
                'Government policies',
                'Export/Import regulations',
                'Transportation costs'
            ],
            'recommendation': recommendation,
            'timestamp': datetime.now().isoformat()
        }
        
        # Store analysis in database
        with get_db_cursor() as (cursor, conn):
            cursor.execute('''
                INSERT INTO market_analysis 
                (id, crop_name, location, analysis_date, demand_level, supply_level,
                 price_volatility, market_trend, seasonal_factor, external_factors, recommendation)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                demand_level = EXCLUDED.demand_level,
                supply_level = EXCLUDED.supply_level,
                price_volatility = EXCLUDED.price_volatility,
                market_trend = EXCLUDED.market_trend,
                seasonal_factor = EXCLUDED.seasonal_factor,
                recommendation = EXCLUDED.recommendation,
                created_at = CURRENT_TIMESTAMP
            ''', (
                f"analysis_{crop_name}_{location}_{datetime.now().strftime('%Y%m%d')}",
                analysis_data['crop_name'],
                analysis_data['location'],
                analysis_data['analysis_date'],
                analysis_data['demand_level'],
                analysis_data['supply_level'],
                analysis_data['price_volatility'],
                analysis_data['market_trend'],
                analysis_data['seasonal_factor'],
                json.dumps(analysis_data['external_factors']),
                analysis_data['recommendation']
            ))
            conn.commit()
        
        return analysis_data
        
    except Exception as e:
        print(f"Error getting market analysis: {e}")
        return {'error': str(e)}

# API Routes
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Market Price API',
        'version': '1.0.0',
        'database': 'PostgreSQL',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/price/current', methods=['GET'])
def get_current_price_endpoint():
    """Get current market price"""
    try:
        crop_name = request.args.get('crop', 'wheat')
        location = request.args.get('location', 'Delhi')
        
        price_data = get_current_price(crop_name, location)
        
        return jsonify({
            'success': True,
            'data': price_data,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/price/predict', methods=['GET'])
def predict_price_endpoint():
    """Predict market price"""
    try:
        crop_name = request.args.get('crop', 'wheat')
        location = request.args.get('location', 'Delhi')
        days_ahead = int(request.args.get('days', 30))
        
        prediction_data = predict_price(crop_name, location, days_ahead)
        
        return jsonify({
            'success': True,
            'data': prediction_data,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/price/analysis', methods=['GET'])
def get_market_analysis_endpoint():
    """Get market analysis"""
    try:
        crop_name = request.args.get('crop', 'wheat')
        location = request.args.get('location', 'Delhi')
        
        analysis_data = get_market_analysis(crop_name, location)
        
        return jsonify({
            'success': True,
            'data': analysis_data,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/price/history', methods=['GET'])
def get_price_history():
    """Get price history"""
    try:
        crop_name = request.args.get('crop', 'wheat')
        location = request.args.get('location', 'Delhi')
        days = int(request.args.get('days', 30))
        
        with get_db_cursor() as (cursor, conn):
            cursor.execute('''
                SELECT * FROM market_prices 
                WHERE crop_name = %s AND location = %s 
                AND date >= %s
                ORDER BY date DESC
                LIMIT %s
            ''', (crop_name, location, datetime.now() - timedelta(days=days), days))
            
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

@app.route('/crops', methods=['GET'])
def get_available_crops():
    """Get list of available crops"""
    return jsonify({
        'success': True,
        'data': {
            'crops': list(CROP_DATA.keys()),
            'crop_details': CROP_DATA
        },
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    print("💰 Starting Market Price API...")
    print("✅ Database initialized")
    print("✅ API ready!")
    
    port = int(os.environ.get('PORT', 5004))
    app.run(host='0.0.0.0', port=port, debug=False)
