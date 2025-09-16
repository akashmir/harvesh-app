"""
Crop Recommendation API with PostgreSQL Integration
Enhanced version with proper database management and ML model integration
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import uuid
from datetime import datetime
from typing import Dict, List, Optional
import numpy as np
import pandas as pd
import joblib
import pickle
import os
import sys

# Add src to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from core.database import get_db, Field, CropHistory, YieldPrediction, init_database, health_check
from sqlalchemy.orm import Session

app = Flask(__name__)
CORS(app)

# Initialize database
init_database()

# Load ML models
try:
    models_dir = os.path.join(os.path.dirname(__file__), 'models')
    # Load Random Forest model
    with open(os.path.join(models_dir, 'random_forest_model.pkl'), 'rb') as f:
        rf_model = pickle.load(f)
    
    # Load scaler
    with open(os.path.join(models_dir, 'scaler.pkl'), 'rb') as f:
        scaler = pickle.load(f)
    
    # Load label encoder
    with open(os.path.join(models_dir, 'label_encoder.pkl'), 'rb') as f:
        label_encoder = pickle.load(f)
    
    print("✅ ML models loaded successfully")
    models_loaded = True
except FileNotFoundError as e:
    print(f"⚠️ ML models not found: {e}")
    models_loaded = False
    rf_model = None
    scaler = None
    label_encoder = None

# Crop data and recommendations
CROP_DATA = {
    'Rice': {
        'season': ['Kharif', 'Rabi'],
        'soil_ph_range': (5.5, 7.5),
        'temperature_range': (20, 35),
        'rainfall_range': (1000, 2000),
        'soil_types': ['clay', 'loamy'],
        'description': 'Staple food crop, requires high water'
    },
    'Wheat': {
        'season': ['Rabi'],
        'soil_ph_range': (6.0, 7.5),
        'temperature_range': (15, 25),
        'rainfall_range': (500, 1000),
        'soil_types': ['loamy', 'clay'],
        'description': 'Winter crop, good for rotation'
    },
    'Maize': {
        'season': ['Kharif'],
        'soil_ph_range': (6.0, 7.0),
        'temperature_range': (18, 27),
        'rainfall_range': (600, 1000),
        'soil_types': ['loamy', 'sandy'],
        'description': 'High yield crop, good for feed'
    },
    'Cotton': {
        'season': ['Kharif'],
        'soil_ph_range': (6.0, 8.0),
        'temperature_range': (21, 30),
        'rainfall_range': (500, 1000),
        'soil_types': ['loamy', 'clay'],
        'description': 'Cash crop, requires good drainage'
    },
    'Sugarcane': {
        'season': ['Kharif', 'Rabi'],
        'soil_ph_range': (6.0, 7.5),
        'temperature_range': (26, 32),
        'rainfall_range': (1000, 1500),
        'soil_types': ['loamy', 'clay'],
        'description': 'Perennial crop, high water requirement'
    }
}

def predict_crop_recommendation(soil_data: Dict) -> Dict:
    """Predict crop recommendation using ML model"""
    if not models_loaded:
        return get_fallback_recommendation(soil_data)
    
    try:
        # Prepare features
        features = np.array([[
            soil_data.get('nitrogen', 0),
            soil_data.get('phosphorus', 0),
            soil_data.get('potassium', 0),
            soil_data.get('temperature', 0),
            soil_data.get('humidity', 0),
            soil_data.get('ph', 0),
            soil_data.get('rainfall', 0)
        ]])
        
        # Scale features
        features_scaled = scaler.transform(features)
        
        # Make prediction
        prediction = rf_model.predict(features_scaled)[0]
        confidence = rf_model.predict_proba(features_scaled).max()
        
        # Decode prediction
        crop_name = label_encoder.inverse_transform([prediction])[0]
        
        return {
            'crop': crop_name,
            'confidence': float(confidence),
            'method': 'ml_model'
        }
    
    except Exception as e:
        print(f"⚠️ ML prediction error: {e}")
        return get_fallback_recommendation(soil_data)

def get_fallback_recommendation(soil_data: Dict) -> Dict:
    """Fallback recommendation based on rules"""
    ph = soil_data.get('ph', 6.5)
    temperature = soil_data.get('temperature', 25)
    rainfall = soil_data.get('rainfall', 1000)
    
    recommendations = []
    
    for crop, data in CROP_DATA.items():
        score = 0
        factors = []
        
        # Check pH compatibility
        ph_min, ph_max = data['soil_ph_range']
        if ph_min <= ph <= ph_max:
            score += 30
            factors.append(f"pH {ph} is suitable")
        else:
            factors.append(f"pH {ph} not optimal (needs {ph_min}-{ph_max})")
        
        # Check temperature compatibility
        temp_min, temp_max = data['temperature_range']
        if temp_min <= temperature <= temp_max:
            score += 25
            factors.append(f"Temperature {temperature}°C is suitable")
        else:
            factors.append(f"Temperature {temperature}°C not optimal (needs {temp_min}-{temp_max}°C)")
        
        # Check rainfall compatibility
        rain_min, rain_max = data['rainfall_range']
        if rain_min <= rainfall <= rain_max:
            score += 25
            factors.append(f"Rainfall {rainfall}mm is suitable")
        else:
            factors.append(f"Rainfall {rainfall}mm not optimal (needs {rain_min}-{rain_max}mm)")
        
        # Check soil type
        soil_type = soil_data.get('soil_type', 'loamy')
        if soil_type in data['soil_types']:
            score += 20
            factors.append(f"Soil type {soil_type} is suitable")
        else:
            factors.append(f"Soil type {soil_type} not ideal (prefers {data['soil_types']})")
        
        recommendations.append({
            'crop': crop,
            'score': score,
            'confidence': score / 100,
            'factors': factors,
            'description': data['description']
        })
    
    # Sort by score
    recommendations.sort(key=lambda x: x['score'], reverse=True)
    
    return {
        'crop': recommendations[0]['crop'],
        'confidence': recommendations[0]['confidence'],
        'method': 'rule_based',
        'all_recommendations': recommendations
    }

def save_recommendation_to_db(field_id: str, recommendation: Dict, soil_data: Dict):
    """Save recommendation to database"""
    try:
        db = next(get_db())
        
        # Create yield prediction record
        yield_prediction = YieldPrediction(
            id=str(uuid.uuid4()),
            field_id=field_id,
            crop_name=recommendation['crop'],
            predicted_yield=0.0,  # Will be calculated by yield prediction API
            confidence_score=recommendation['confidence'],
            soil_ph=soil_data.get('ph'),
            soil_moisture=soil_data.get('moisture'),
            temperature=soil_data.get('temperature'),
            rainfall=soil_data.get('rainfall'),
            area_hectares=soil_data.get('area_hectares', 1.0),
            season=soil_data.get('season', 'Kharif'),
            prediction_factors=json.dumps(recommendation.get('factors', []))
        )
        
        db.add(yield_prediction)
        db.commit()
        db.close()
        
    except Exception as e:
        print(f"⚠️ Error saving to database: {e}")

# API Endpoints

@app.route('/health', methods=['GET'])
def health_check_endpoint():
    """Health check endpoint"""
    db_healthy = health_check()
    
    return jsonify({
        "success": True,
        "message": "Crop Recommendation API is running",
        "timestamp": datetime.now().isoformat(),
        "database_healthy": db_healthy,
        "ml_models_loaded": models_loaded,
        "available_crops": len(CROP_DATA)
    })

@app.route('/recommend', methods=['POST'])
def recommend_crop():
    """Get crop recommendation based on soil and weather data"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['ph', 'temperature', 'rainfall']
        for field in required_fields:
            if field not in data:
                return jsonify({
                    "success": False,
                    "error": f"Missing required field: {field}"
                }), 400
        
        # Get recommendation
        recommendation = predict_crop_recommendation(data)
        
        # Save to database if field_id provided
        field_id = data.get('field_id')
        if field_id:
            save_recommendation_to_db(field_id, recommendation, data)
        
        return jsonify({
            "success": True,
            "data": {
                "recommendation": recommendation,
                "soil_data": data,
                "timestamp": datetime.now().isoformat()
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/crops', methods=['GET'])
def get_available_crops():
    """Get list of available crops with their requirements"""
    return jsonify({
        "success": True,
        "data": {
            "crops": CROP_DATA,
            "total_crops": len(CROP_DATA)
        }
    })

@app.route('/crops/<crop_name>', methods=['GET'])
def get_crop_details(crop_name: str):
    """Get detailed information about a specific crop"""
    if crop_name not in CROP_DATA:
        return jsonify({
            "success": False,
            "error": "Crop not found"
        }), 404
    
    return jsonify({
        "success": True,
        "data": {
            "crop": crop_name,
            "details": CROP_DATA[crop_name]
        }
    })

@app.route('/recommendations', methods=['GET'])
def get_recommendations_history():
    """Get crop recommendation history"""
    try:
        field_id = request.args.get('field_id')
        
        db = next(get_db())
        query = db.query(YieldPrediction)
        
        if field_id:
            query = query.filter(YieldPrediction.field_id == field_id)
        
        recommendations = query.order_by(YieldPrediction.created_at.desc()).limit(50).all()
        
        result = []
        for rec in recommendations:
            result.append({
                'id': rec.id,
                'field_id': rec.field_id,
                'crop_name': rec.crop_name,
                'confidence_score': rec.confidence_score,
                'prediction_date': rec.prediction_date.isoformat(),
                'soil_ph': rec.soil_ph,
                'temperature': rec.temperature,
                'rainfall': rec.rainfall,
                'season': rec.season,
                'prediction_factors': json.loads(rec.prediction_factors) if rec.prediction_factors else []
            })
        
        db.close()
        
        return jsonify({
            "success": True,
            "data": {
                "recommendations": result,
                "total_recommendations": len(result)
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/analyze', methods=['POST'])
def analyze_soil():
    """Analyze soil conditions and provide detailed recommendations"""
    try:
        data = request.get_json()
        
        # Get basic recommendation
        recommendation = predict_crop_recommendation(data)
        
        # Add detailed analysis
        analysis = {
            'soil_health': {
                'ph_status': 'Optimal' if 6.0 <= data.get('ph', 6.5) <= 7.0 else 'Needs adjustment',
                'nutrient_level': 'Good' if all(data.get(n, 0) > 0 for n in ['nitrogen', 'phosphorus', 'potassium']) else 'Needs fertilization',
                'moisture_level': 'Adequate' if 40 <= data.get('moisture', 50) <= 80 else 'Needs irrigation'
            },
            'weather_conditions': {
                'temperature_suitable': True,
                'rainfall_adequate': data.get('rainfall', 1000) >= 500,
                'humidity_optimal': 40 <= data.get('humidity', 60) <= 80
            },
            'recommendations': {
                'primary_crop': recommendation['crop'],
                'confidence': recommendation['confidence'],
                'alternative_crops': recommendation.get('all_recommendations', [])[1:3] if 'all_recommendations' in recommendation else [],
                'improvements': []
            }
        }
        
        # Add improvement suggestions
        if data.get('ph', 6.5) < 6.0:
            analysis['recommendations']['improvements'].append("Add lime to increase soil pH")
        elif data.get('ph', 6.5) > 7.5:
            analysis['recommendations']['improvements'].append("Add sulfur to decrease soil pH")
        
        if data.get('moisture', 50) < 40:
            analysis['recommendations']['improvements'].append("Increase irrigation frequency")
        elif data.get('moisture', 50) > 80:
            analysis['recommendations']['improvements'].append("Improve drainage")
        
        return jsonify({
            "success": True,
            "data": {
                "analysis": analysis,
                "soil_data": data,
                "timestamp": datetime.now().isoformat()
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

if __name__ == '__main__':
    print("🌾 Crop Recommendation API with PostgreSQL Starting...")
    print(f"📊 Database: PostgreSQL")
    print(f"🤖 ML Models: {'Loaded' if models_loaded else 'Not available'}")
    print(f"🌱 Available crops: {len(CROP_DATA)}")
    print("🚀 Server running on http://0.0.0.0:8080")
    print("📱 Android emulator can access via http://10.0.2.2:8080")
    app.run(debug=True, host='0.0.0.0', port=8080)

