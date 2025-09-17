"""
Market Price Prediction & Profit Calculator API
Provides real-time market prices, price predictions, and profit calculations for crops
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import sqlite3
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import requests
import random

app = Flask(__name__)
CORS(app)

# Database setup
DB_NAME = 'market_price.db'

def init_database():
    """Initialize the market price database"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    # Market prices table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS market_prices (
            id TEXT PRIMARY KEY,
            crop_name TEXT NOT NULL,
            price_per_kg REAL NOT NULL,
            market_name TEXT NOT NULL,
            state TEXT NOT NULL,
            date DATE NOT NULL,
            price_type TEXT NOT NULL,
            source TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Price predictions table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS price_predictions (
            id TEXT PRIMARY KEY,
            crop_name TEXT NOT NULL,
            predicted_price REAL NOT NULL,
            confidence_score REAL NOT NULL,
            prediction_date DATE NOT NULL,
            target_date DATE NOT NULL,
            market_name TEXT,
            state TEXT,
            factors TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Profit calculations table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS profit_calculations (
            id TEXT PRIMARY KEY,
            crop_name TEXT NOT NULL,
            yield_prediction REAL NOT NULL,
            area_hectares REAL NOT NULL,
            market_price REAL NOT NULL,
            total_revenue REAL NOT NULL,
            production_cost REAL NOT NULL,
            net_profit REAL NOT NULL,
            profit_margin REAL NOT NULL,
            calculation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    conn.commit()
    conn.close()

# Initialize database
init_database()

# Market price data (simulated real-time data)
MARKET_PRICES = {
    'Rice': {
        'baseline_price': 25.0,
        'price_range': (20, 35),
        'seasonal_adjustment': 0.15,
        'market_demand': 'high'
    },
    'Wheat': {
        'baseline_price': 22.0,
        'price_range': (18, 28),
        'seasonal_adjustment': 0.12,
        'market_demand': 'high'
    },
    'Maize': {
        'baseline_price': 18.0,
        'price_range': (15, 25),
        'seasonal_adjustment': 0.10,
        'market_demand': 'medium'
    },
    'Cotton': {
        'baseline_price': 65.0,
        'price_range': (55, 80),
        'seasonal_adjustment': 0.20,
        'market_demand': 'high'
    },
    'Sugarcane': {
        'baseline_price': 3.2,
        'price_range': (2.8, 4.0),
        'seasonal_adjustment': 0.08,
        'market_demand': 'medium'
    },
    'Potato': {
        'baseline_price': 15.0,
        'price_range': (12, 20),
        'seasonal_adjustment': 0.25,
        'market_demand': 'medium'
    },
    'Tomato': {
        'baseline_price': 35.0,
        'price_range': (25, 50),
        'seasonal_adjustment': 0.30,
        'market_demand': 'high'
    },
    'Onion': {
        'baseline_price': 28.0,
        'price_range': (20, 40),
        'seasonal_adjustment': 0.35,
        'market_demand': 'high'
    }
}

# Production cost estimates (per hectare)
PRODUCTION_COSTS = {
    'Rice': {
        'seeds': 2500,
        'fertilizers': 8000,
        'pesticides': 3000,
        'labor': 12000,
        'machinery': 5000,
        'irrigation': 2000,
        'other': 1500
    },
    'Wheat': {
        'seeds': 2000,
        'fertilizers': 6000,
        'pesticides': 2500,
        'labor': 8000,
        'machinery': 4000,
        'irrigation': 1500,
        'other': 1000
    },
    'Maize': {
        'seeds': 3000,
        'fertilizers': 7000,
        'pesticides': 3500,
        'labor': 10000,
        'machinery': 4500,
        'irrigation': 1800,
        'other': 1200
    },
    'Cotton': {
        'seeds': 4000,
        'fertilizers': 10000,
        'pesticides': 8000,
        'labor': 15000,
        'machinery': 6000,
        'irrigation': 3000,
        'other': 2000
    },
    'Sugarcane': {
        'seeds': 5000,
        'fertilizers': 12000,
        'pesticides': 4000,
        'labor': 20000,
        'machinery': 8000,
        'irrigation': 4000,
        'other': 3000
    },
    'Potato': {
        'seeds': 8000,
        'fertilizers': 6000,
        'pesticides': 4000,
        'labor': 12000,
        'machinery': 3000,
        'irrigation': 2000,
        'other': 1500
    },
    'Tomato': {
        'seeds': 2000,
        'fertilizers': 5000,
        'pesticides': 6000,
        'labor': 15000,
        'machinery': 2000,
        'irrigation': 3000,
        'other': 2000
    },
    'Onion': {
        'seeds': 1500,
        'fertilizers': 4000,
        'pesticides': 3000,
        'labor': 10000,
        'machinery': 2000,
        'irrigation': 2000,
        'other': 1500
    }
}

def get_current_market_price(crop_name: str, state: str = "All India") -> Dict:
    """Get current market price for a crop"""
    if crop_name not in MARKET_PRICES:
        crop_name = 'Rice'  # Default fallback
    
    price_data = MARKET_PRICES[crop_name]
    baseline = price_data['baseline_price']
    price_range = price_data['price_range']
    
    # Simulate price variation based on market conditions
    variation = random.uniform(-0.1, 0.1)  # ±10% variation
    current_price = baseline * (1 + variation)
    
    # Ensure price is within realistic range
    current_price = max(price_range[0], min(price_range[1], current_price))
    
    return {
        'crop_name': crop_name,
        'current_price': round(current_price, 2),
        'price_range': price_range,
        'market_demand': price_data['market_demand'],
        'state': state,
        'date': datetime.now().strftime('%Y-%m-%d'),
        'price_type': 'wholesale'
    }

def predict_market_price(crop_name: str, days_ahead: int = 30) -> Dict:
    """Predict market price for a crop"""
    if crop_name not in MARKET_PRICES:
        crop_name = 'Rice'
    
    price_data = MARKET_PRICES[crop_name]
    baseline = price_data['baseline_price']
    seasonal_adj = price_data['seasonal_adjustment']
    
    # Simple prediction model (in real app, use ML models)
    # Factors: seasonal trends, market demand, historical patterns
    seasonal_factor = 1 + (seasonal_adj * np.sin(days_ahead / 30 * 2 * np.pi))
    demand_factor = 1.1 if price_data['market_demand'] == 'high' else 1.0
    
    predicted_price = baseline * seasonal_factor * demand_factor
    
    # Add some randomness for realism
    noise = random.uniform(-0.05, 0.05)
    predicted_price *= (1 + noise)
    
    confidence = max(0.6, 1.0 - (days_ahead / 90))  # Confidence decreases with time
    
    return {
        'crop_name': crop_name,
        'predicted_price': round(predicted_price, 2),
        'confidence_score': round(confidence, 3),
        'prediction_date': datetime.now().strftime('%Y-%m-%d'),
        'target_date': (datetime.now() + timedelta(days=days_ahead)).strftime('%Y-%m-%d'),
        'factors': {
            'seasonal_trend': round(seasonal_factor, 3),
            'market_demand': price_data['market_demand'],
            'days_ahead': days_ahead
        }
    }

def calculate_profit(crop_name: str, yield_kg: float, area_hectares: float, 
                    market_price: float = None) -> Dict:
    """Calculate profit for a crop"""
    if crop_name not in PRODUCTION_COSTS:
        crop_name = 'Rice'
    
    # Get market price if not provided
    if market_price is None:
        price_data = get_current_market_price(crop_name)
        market_price = price_data['current_price']
    
    # Calculate total revenue
    total_revenue = yield_kg * market_price
    
    # Calculate production costs
    cost_data = PRODUCTION_COSTS[crop_name]
    total_cost = sum(cost_data.values()) * area_hectares
    
    # Calculate profit
    net_profit = total_revenue - total_cost
    profit_margin = (net_profit / total_revenue * 100) if total_revenue > 0 else 0
    
    # Cost breakdown
    cost_breakdown = {
        'seeds': cost_data['seeds'] * area_hectares,
        'fertilizers': cost_data['fertilizers'] * area_hectares,
        'pesticides': cost_data['pesticides'] * area_hectares,
        'labor': cost_data['labor'] * area_hectares,
        'machinery': cost_data['machinery'] * area_hectares,
        'irrigation': cost_data['irrigation'] * area_hectares,
        'other': cost_data['other'] * area_hectares
    }
    
    return {
        'crop_name': crop_name,
        'yield_kg': yield_kg,
        'area_hectares': area_hectares,
        'market_price': market_price,
        'total_revenue': round(total_revenue, 2),
        'total_cost': round(total_cost, 2),
        'net_profit': round(net_profit, 2),
        'profit_margin': round(profit_margin, 2),
        'cost_breakdown': cost_breakdown,
        'calculation_date': datetime.now().strftime('%Y-%m-%d')
    }

# API Endpoints

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "success": True,
        "message": "Market Price API is running",
        "timestamp": datetime.now().isoformat(),
        "available_crops": len(MARKET_PRICES)
    })

@app.route('/price/current', methods=['GET'])
def get_current_price():
    """Get current market price for a crop"""
    try:
        crop_name = request.args.get('crop', 'Rice')
        state = request.args.get('state', 'All India')
        
        price_data = get_current_market_price(crop_name, state)
        
        # Store in database
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        price_id = f"price_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{hash(crop_name) % 10000}"
        
        cursor.execute('''
            INSERT INTO market_prices 
            (id, crop_name, price_per_kg, market_name, state, date, price_type, source)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            price_id,
            crop_name,
            price_data['current_price'],
            'Wholesale Market',
            state,
            price_data['date'],
            price_data['price_type'],
            'API'
        ))
        
        conn.commit()
        conn.close()
        
        return jsonify({
            "success": True,
            "data": price_data
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/price/predict', methods=['POST'])
def predict_price():
    """Predict future market price"""
    try:
        data = request.get_json()
        crop_name = data.get('crop_name', 'Rice')
        days_ahead = data.get('days_ahead', 30)
        
        prediction = predict_market_price(crop_name, days_ahead)
        
        # Store prediction in database
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        pred_id = f"pred_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{hash(crop_name) % 10000}"
        
        cursor.execute('''
            INSERT INTO price_predictions 
            (id, crop_name, predicted_price, confidence_score, prediction_date, 
             target_date, market_name, state, factors)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            pred_id,
            crop_name,
            prediction['predicted_price'],
            prediction['confidence_score'],
            prediction['prediction_date'],
            prediction['target_date'],
            'Wholesale Market',
            'All India',
            json.dumps(prediction['factors'])
        ))
        
        conn.commit()
        conn.close()
        
        return jsonify({
            "success": True,
            "data": prediction
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/profit/calculate', methods=['POST'])
def calculate_profit_endpoint():
    """Calculate profit for a crop"""
    try:
        data = request.get_json()
        
        required_fields = ['crop_name', 'yield_kg', 'area_hectares']
        for field in required_fields:
            if field not in data:
                return jsonify({
                    "success": False,
                    "error": f"Missing required field: {field}"
                }), 400
        
        profit_data = calculate_profit(
            data['crop_name'],
            data['yield_kg'],
            data['area_hectares'],
            data.get('market_price')
        )
        
        # Store calculation in database
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        calc_id = f"calc_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{hash(str(data)) % 10000}"
        
        cursor.execute('''
            INSERT INTO profit_calculations 
            (id, crop_name, yield_prediction, area_hectares, market_price,
             total_revenue, production_cost, net_profit, profit_margin)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            calc_id,
            data['crop_name'],
            data['yield_kg'],
            data['area_hectares'],
            profit_data['market_price'],
            profit_data['total_revenue'],
            profit_data['total_cost'],
            profit_data['net_profit'],
            profit_data['profit_margin']
        ))
        
        conn.commit()
        conn.close()
        
        return jsonify({
            "success": True,
            "data": profit_data
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/crops', methods=['GET'])
def get_available_crops():
    """Get list of crops with price information"""
    return jsonify({
        "success": True,
        "data": {
            "crops": MARKET_PRICES,
            "production_costs": PRODUCTION_COSTS,
            "total_crops": len(MARKET_PRICES)
        }
    })

@app.route('/prices/history', methods=['GET'])
def get_price_history():
    """Get historical price data"""
    try:
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        crop_name = request.args.get('crop_name')
        days = int(request.args.get('days', 30))
        
        query = '''
            SELECT * FROM market_prices 
            WHERE date >= date('now', '-{} days')
        '''.format(days)
        
        params = []
        if crop_name:
            query += ' AND crop_name = ?'
            params.append(crop_name)
        
        query += ' ORDER BY date DESC'
        
        cursor.execute(query, params)
        rows = cursor.fetchall()
        
        history = []
        for row in rows:
            history.append({
                'id': row[0],
                'crop_name': row[1],
                'price_per_kg': row[2],
                'market_name': row[3],
                'state': row[4],
                'date': row[5],
                'price_type': row[6],
                'source': row[7],
                'created_at': row[8]
            })
        
        conn.close()
        
        return jsonify({
            "success": True,
            "data": {
                "price_history": history,
                "total_records": len(history)
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/mandis', methods=['GET'])
def get_mandis():
    """Get list of mandis with coordinates"""
    try:
        # Sample mandi data (in production, this would come from Agmarknet API)
        mandis = [
            {
                'mandi_name': 'Azadpur Mandi',
                'state': 'Delhi',
                'district': 'North Delhi',
                'latitude': 28.7041,
                'longitude': 77.1025,
                'crops_available': ['Tomato', 'Onion', 'Potato', 'Rice', 'Wheat']
            },
            {
                'mandi_name': 'Ghazipur Mandi',
                'state': 'Delhi',
                'district': 'East Delhi',
                'latitude': 28.6200,
                'longitude': 77.3200,
                'crops_available': ['Rice', 'Wheat', 'Maize', 'Cotton']
            },
            {
                'mandi_name': 'Anandpur Sahib Mandi',
                'state': 'Punjab',
                'district': 'Rupnagar',
                'latitude': 31.2359,
                'longitude': 76.4974,
                'crops_available': ['Rice', 'Wheat', 'Maize', 'Sugarcane']
            },
            {
                'mandi_name': 'Ludhiana Mandi',
                'state': 'Punjab',
                'district': 'Ludhiana',
                'latitude': 30.9010,
                'longitude': 75.8573,
                'crops_available': ['Wheat', 'Rice', 'Cotton', 'Sugarcane']
            },
            {
                'mandi_name': 'Karnal Mandi',
                'state': 'Haryana',
                'district': 'Karnal',
                'latitude': 29.6857,
                'longitude': 76.9905,
                'crops_available': ['Rice', 'Wheat', 'Maize', 'Mustard']
            },
            {
                'mandi_name': 'Hisar Mandi',
                'state': 'Haryana',
                'district': 'Hisar',
                'latitude': 29.1492,
                'longitude': 75.7217,
                'crops_available': ['Wheat', 'Cotton', 'Sugarcane', 'Mustard']
            },
            {
                'mandi_name': 'Agra Mandi',
                'state': 'Uttar Pradesh',
                'district': 'Agra',
                'latitude': 27.1767,
                'longitude': 78.0081,
                'crops_available': ['Wheat', 'Rice', 'Sugarcane', 'Potato']
            },
            {
                'mandi_name': 'Lucknow Mandi',
                'state': 'Uttar Pradesh',
                'district': 'Lucknow',
                'latitude': 26.8467,
                'longitude': 80.9462,
                'crops_available': ['Rice', 'Wheat', 'Sugarcane', 'Potato']
            },
            {
                'mandi_name': 'Pune Mandi',
                'state': 'Maharashtra',
                'district': 'Pune',
                'latitude': 18.5204,
                'longitude': 73.8567,
                'crops_available': ['Sugarcane', 'Cotton', 'Soybean', 'Wheat']
            },
            {
                'mandi_name': 'Nagpur Mandi',
                'state': 'Maharashtra',
                'district': 'Nagpur',
                'latitude': 21.1458,
                'longitude': 79.0882,
                'crops_available': ['Cotton', 'Soybean', 'Wheat', 'Rice']
            }
        ]
        
        return jsonify({
            "success": True,
            "data": mandis,
            "total_mandis": len(mandis)
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/mandis/nearest', methods=['GET'])
def get_nearest_mandis():
    """Get nearest mandis to user's location"""
    try:
        latitude = float(request.args.get('latitude', 0))
        longitude = float(request.args.get('longitude', 0))
        limit = int(request.args.get('limit', 5))
        
        if latitude == 0 and longitude == 0:
            return jsonify({
                "success": False,
                "error": "Invalid coordinates provided"
            }), 400
        
        # Get all mandis
        mandis_response = get_mandis()
        if not mandis_response[0].get('success'):
            return mandis_response
        
        mandis = mandis_response[0].get('data', [])
        
        # Calculate distances
        for mandi in mandis:
            distance = calculate_distance(
                latitude, longitude,
                mandi['latitude'], mandi['longitude']
            )
            mandi['distance_km'] = round(distance, 2)
        
        # Sort by distance and return top results
        mandis.sort(key=lambda x: x['distance_km'])
        nearest_mandis = mandis[:limit]
        
        return jsonify({
            "success": True,
            "data": nearest_mandis,
            "user_location": {
                "latitude": latitude,
                "longitude": longitude
            },
            "total_found": len(nearest_mandis)
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/mandis/prices', methods=['GET'])
def get_mandi_prices():
    """Get prices for crops in a specific mandi"""
    try:
        mandi_name = request.args.get('mandi_name')
        if not mandi_name:
            return jsonify({
                "success": False,
                "error": "Mandi name is required"
            }), 400
        
        # Generate sample prices for the mandi
        prices = generate_mandi_prices(mandi_name)
        
        return jsonify({
            "success": True,
            "data": prices,
            "mandi_name": mandi_name,
            "total_crops": len(prices)
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/prices/location-based', methods=['GET'])
def get_location_based_prices():
    """Get prices from nearest mandis based on user location"""
    try:
        latitude = float(request.args.get('latitude', 0))
        longitude = float(request.args.get('longitude', 0))
        
        if latitude == 0 and longitude == 0:
            return jsonify({
                "success": False,
                "error": "Invalid coordinates provided"
            }), 400
        
        # Get nearest mandis
        nearest_response = get_nearest_mandis()
        if not nearest_response[0].get('success'):
            return nearest_response
        
        nearest_mandis = nearest_response[0].get('data', [])
        
        # Get prices from nearest mandis
        all_prices = []
        for mandi in nearest_mandis[:3]:  # Top 3 nearest mandis
            prices = generate_mandi_prices(mandi['mandi_name'])
            for price in prices:
                price['mandi_name'] = mandi['mandi_name']
                price['mandi_distance'] = mandi['distance_km']
                price['mandi_state'] = mandi['state']
                price['mandi_district'] = mandi['district']
            all_prices.extend(prices)
        
        return jsonify({
            "success": True,
            "data": all_prices,
            "nearest_mandi": nearest_mandis[0] if nearest_mandis else None,
            "total_mandis": len(nearest_mandis),
            "total_prices": len(all_prices)
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two coordinates using Haversine formula"""
    import math
    
    R = 6371  # Earth's radius in kilometers
    
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    
    a = (math.sin(dlat/2) * math.sin(dlat/2) +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon/2) * math.sin(dlon/2))
    
    c = 2 * math.asin(math.sqrt(a))
    
    return R * c

def generate_mandi_prices(mandi_name):
    """Generate sample prices for a mandi"""
    base_prices = {
        'Rice': {'min': 20, 'max': 35, 'unit': 'kg'},
        'Wheat': {'min': 18, 'max': 28, 'unit': 'kg'},
        'Maize': {'min': 15, 'max': 25, 'unit': 'kg'},
        'Cotton': {'min': 55, 'max': 80, 'unit': 'kg'},
        'Sugarcane': {'min': 2.8, 'max': 4.0, 'unit': 'kg'},
        'Potato': {'min': 12, 'max': 20, 'unit': 'kg'},
        'Tomato': {'min': 25, 'max': 50, 'unit': 'kg'},
        'Onion': {'min': 20, 'max': 40, 'unit': 'kg'},
        'Soybean': {'min': 30, 'max': 45, 'unit': 'kg'},
        'Mustard': {'min': 40, 'max': 60, 'unit': 'kg'},
    }
    
    prices = []
    for crop, price_data in base_prices.items():
        random_factor = random.uniform(0, 1)
        price = price_data['min'] + (price_data['max'] - price_data['min']) * random_factor
        
        prices.append({
            'crop_name': crop,
            'current_price': round(price, 2),
            'unit': price_data['unit'],
            'price_type': 'wholesale',
            'date': datetime.now().strftime('%Y-%m-%d'),
            'market_demand': get_market_demand(price, price_data['min'], price_data['max']),
            'price_trend': random.choice(['up', 'down', 'stable']),
            'min_price': price_data['min'],
            'max_price': price_data['max'],
        })
    
    return prices

def get_market_demand(price, min_price, max_price):
    """Determine market demand based on price"""
    range_val = max_price - min_price
    position = (price - min_price) / range_val
    
    if position < 0.3:
        return 'Low'
    elif position < 0.7:
        return 'Medium'
    else:
        return 'High'

@app.route('/analytics', methods=['GET'])
def get_market_analytics():
    """Get market analytics and insights"""
    try:
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        # Get price trends
        cursor.execute('''
            SELECT crop_name, AVG(price_per_kg) as avg_price, 
                   MIN(price_per_kg) as min_price, MAX(price_per_kg) as max_price,
                   COUNT(*) as record_count
            FROM market_prices 
            WHERE date >= date('now', '-30 days')
            GROUP BY crop_name
        ''')
        
        price_trends = []
        for row in cursor.fetchall():
            price_trends.append({
                'crop_name': row[0],
                'avg_price': round(row[1], 2),
                'min_price': round(row[2], 2),
                'max_price': round(row[3], 2),
                'record_count': row[4]
            })
        
        # Get profit analytics
        cursor.execute('''
            SELECT crop_name, AVG(net_profit) as avg_profit,
                   AVG(profit_margin) as avg_margin, COUNT(*) as calc_count
            FROM profit_calculations 
            WHERE calculation_date >= date('now', '-30 days')
            GROUP BY crop_name
        ''')
        
        profit_analytics = []
        for row in cursor.fetchall():
            profit_analytics.append({
                'crop_name': row[0],
                'avg_profit': round(row[1], 2),
                'avg_margin': round(row[2], 2),
                'calc_count': row[3]
            })
        
        conn.close()
        
        return jsonify({
            "success": True,
            "data": {
                "price_trends": price_trends,
                "profit_analytics": profit_analytics,
                "insights": {
                    "most_profitable_crop": max(profit_analytics, key=lambda x: x['avg_profit'])['crop_name'] if profit_analytics else None,
                    "highest_price_crop": max(price_trends, key=lambda x: x['avg_price'])['crop_name'] if price_trends else None,
                    "total_calculations": sum(p['calc_count'] for p in profit_analytics)
                }
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

if __name__ == '__main__':
    print("💰 Market Price Prediction API Starting...")
    print(f"📊 Database: {DB_NAME}")
    print(f"🌾 Available crops: {len(MARKET_PRICES)}")
    print(f"💵 Production costs: {len(PRODUCTION_COSTS)} crops")
    print("🚀 Server running on http://0.0.0.0:5004")
    print("📱 Android emulator can access via http://10.0.2.2:5004")
    app.run(debug=True, host='0.0.0.0', port=5004)
