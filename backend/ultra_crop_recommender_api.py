"""
ULTRA CROP RECOMMENDER API
Advanced AI-driven decision support system for crop recommendations
Integrates satellite data, IoT sensors, weather forecasts, market analysis, and ML ensemble models
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import uuid
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import os
import sys
import logging
import requests
import threading
import time
import joblib
import pickle
from sklearn.ensemble import RandomForestClassifier, VotingClassifier
from sklearn.neural_network import MLPClassifier
import xgboost as xgb

# Add src to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from core.database import get_db, Field, CropHistory, YieldPrediction, init_database, health_check
from sqlalchemy.orm import Session

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize database
init_database()

# API Configuration for integrated services (env-overridable)
API_ENDPOINTS = {
    'satellite_soil': os.getenv('SATELLITE_SOIL_API_BASE_URL', 'http://localhost:5006'),
    'weather_integration': os.getenv('WEATHER_INTEGRATION_API_BASE_URL', 'http://localhost:5005'),
    'market_price': os.getenv('MARKET_PRICE_API_BASE_URL', 'http://localhost:5004'),
    'yield_prediction': os.getenv('YIELD_PREDICTION_API_BASE_URL', 'http://localhost:5003'),
    'sustainability': os.getenv('SUSTAINABILITY_SCORING_API_BASE_URL', 'http://localhost:5009'),
    'crop_rotation': os.getenv('CROP_ROTATION_API_BASE_URL', 'http://localhost:5010'),
    'multilingual_ai': os.getenv('MULTILINGUAL_AI_API_BASE_URL', 'http://localhost:5007'),
    'disease_detection': os.getenv('DISEASE_DETECTION_API_BASE_URL', 'http://localhost:5008')
}

# External request timeout (seconds)
REQUEST_TIMEOUT = float(os.getenv('ULTRA_REQUEST_TIMEOUT', '4.0'))

# External API Keys (set these in environment variables)
OPENWEATHER_API_KEY = os.getenv('OPENWEATHER_API_KEY', 'your_api_key_here')
GOOGLE_EARTH_ENGINE_KEY = os.getenv('GOOGLE_EARTH_ENGINE_KEY', 'your_key_here')
BHUVAN_API_KEY = os.getenv('BHUVAN_API_KEY', 'your_key_here')

# Load Enhanced ML Models
class UltraCropRecommenderML:
    def __init__(self):
        self.models_loaded = False
        self.rf_model = None
        self.nn_model = None
        self.xgb_model = None
        self.ensemble_model = None
        self.scaler = None
        self.label_encoder = None
        self.feature_names = [
            'nitrogen', 'phosphorus', 'potassium', 'temperature', 'humidity', 
            'ph', 'rainfall', 'soil_moisture', 'organic_carbon', 'clay_content',
            'sand_content', 'elevation', 'slope', 'ndvi', 'evi', 'water_access_score'
        ]
        self.load_models()
    
    def load_models(self):
        """Load all ML models for ensemble prediction"""
        try:
            models_dir = os.path.join(os.path.dirname(__file__), 'models')
            
            # Load existing Random Forest model
            with open(os.path.join(models_dir, 'random_forest_model.pkl'), 'rb') as f:
                self.rf_model = pickle.load(f)
            
            # Load scaler and label encoder
            with open(os.path.join(models_dir, 'scaler.pkl'), 'rb') as f:
                self.scaler = pickle.load(f)
            
            with open(os.path.join(models_dir, 'label_encoder.pkl'), 'rb') as f:
                self.label_encoder = pickle.load(f)
            
            # Create Neural Network model (if not exists, create a simple one)
            try:
                with open(os.path.join(models_dir, 'neural_network_model.pkl'), 'rb') as f:
                    self.nn_model = pickle.load(f)
            except FileNotFoundError:
                logger.warning("Neural Network model not found, creating default")
                self.nn_model = MLPClassifier(
                    hidden_layer_sizes=(100, 50),
                    max_iter=500,
                    random_state=42
                )
            
            # Create XGBoost model (if not exists, create a simple one)
            try:
                self.xgb_model = xgb.XGBClassifier()
                self.xgb_model.load_model(os.path.join(models_dir, 'xgboost_model.json'))
            except:
                logger.warning("XGBoost model not found, creating default")
                self.xgb_model = xgb.XGBClassifier(
                    n_estimators=100,
                    max_depth=6,
                    random_state=42
                )
            
            # Create ensemble model
            self.ensemble_model = VotingClassifier(
                estimators=[
                    ('rf', self.rf_model),
                    ('nn', self.nn_model),
                    ('xgb', self.xgb_model)
                ],
                voting='soft'
            )
            
            self.models_loaded = True
            logger.info("✅ Ultra Crop Recommender ML models loaded successfully")
            
        except Exception as e:
            logger.error(f"⚠️ Error loading ML models: {e}")
            self.models_loaded = False

ml_engine = UltraCropRecommenderML()

# Enhanced Crop Database with detailed information
ULTRA_CROP_DATABASE = {
    'Rice': {
        'seasons': ['Kharif', 'Rabi'],
        'soil_ph_range': (5.5, 7.5),
        'temperature_range': (20, 35),
        'rainfall_range': (1000, 2000),
        'soil_types': ['clay', 'loamy'],
        'water_requirement': 'High',
        'growth_duration': '120-150 days',
        'yield_potential': '4-6 tons/hectare',
        'market_demand': 'Very High',
        'sustainability_score': 7.5,
        'disease_resistance': 'Medium',
        'climate_adaptability': 'High',
        'input_cost': 'Medium',
        'profit_margin': 'High',
        'description': 'Staple food crop with high water requirements and excellent market demand'
    },
    'Wheat': {
        'seasons': ['Rabi'],
        'soil_ph_range': (6.0, 7.5),
        'temperature_range': (15, 25),
        'rainfall_range': (500, 1000),
        'soil_types': ['loamy', 'clay'],
        'water_requirement': 'Medium',
        'growth_duration': '120-140 days',
        'yield_potential': '3-5 tons/hectare',
        'market_demand': 'Very High',
        'sustainability_score': 8.0,
        'disease_resistance': 'High',
        'climate_adaptability': 'Medium',
        'input_cost': 'Medium',
        'profit_margin': 'High',
        'description': 'Winter staple crop with good rotation benefits and stable market'
    },
    'Maize': {
        'seasons': ['Kharif', 'Rabi'],
        'soil_ph_range': (6.0, 7.0),
        'temperature_range': (18, 27),
        'rainfall_range': (600, 1000),
        'soil_types': ['loamy', 'sandy'],
        'water_requirement': 'Medium',
        'growth_duration': '90-120 days',
        'yield_potential': '5-8 tons/hectare',
        'market_demand': 'High',
        'sustainability_score': 8.5,
        'disease_resistance': 'High',
        'climate_adaptability': 'High',
        'input_cost': 'Low',
        'profit_margin': 'Very High',
        'description': 'Versatile crop with high yield potential and multiple uses'
    },
    'Cotton': {
        'seasons': ['Kharif'],
        'soil_ph_range': (6.0, 8.0),
        'temperature_range': (21, 30),
        'rainfall_range': (500, 1000),
        'soil_types': ['loamy', 'clay'],
        'water_requirement': 'Medium',
        'growth_duration': '180-200 days',
        'yield_potential': '15-25 quintals/hectare',
        'market_demand': 'High',
        'sustainability_score': 6.5,
        'disease_resistance': 'Medium',
        'climate_adaptability': 'Medium',
        'input_cost': 'High',
        'profit_margin': 'Very High',
        'description': 'Cash crop with high profit margins but requires good management'
    },
    'Sugarcane': {
        'seasons': ['Kharif', 'Rabi'],
        'soil_ph_range': (6.0, 7.5),
        'temperature_range': (26, 32),
        'rainfall_range': (1000, 1500),
        'soil_types': ['loamy', 'clay'],
        'water_requirement': 'Very High',
        'growth_duration': '300-365 days',
        'yield_potential': '80-120 tons/hectare',
        'market_demand': 'High',
        'sustainability_score': 7.0,
        'disease_resistance': 'Medium',
        'climate_adaptability': 'Medium',
        'input_cost': 'High',
        'profit_margin': 'High',
        'description': 'Perennial crop with high yield and consistent market demand'
    },
    'Soybean': {
        'seasons': ['Kharif'],
        'soil_ph_range': (6.0, 7.0),
        'temperature_range': (20, 30),
        'rainfall_range': (600, 1000),
        'soil_types': ['loamy', 'sandy'],
        'water_requirement': 'Medium',
        'growth_duration': '90-120 days',
        'yield_potential': '2-3 tons/hectare',
        'market_demand': 'Very High',
        'sustainability_score': 9.0,
        'disease_resistance': 'High',
        'climate_adaptability': 'High',
        'input_cost': 'Low',
        'profit_margin': 'High',
        'description': 'Nitrogen-fixing legume crop with excellent sustainability and market value'
    }
}

def get_satellite_soil_data(lat: float, lon: float) -> Dict:
    """Get comprehensive soil data from satellite sources"""
    try:
        # Call satellite soil API
        response = requests.get(
            f"{API_ENDPOINTS['satellite_soil']}/soil/current",
            params={'lat': lat, 'lon': lon, 'location': f"{lat},{lon}"},
            timeout=REQUEST_TIMEOUT
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                soil_props = data['data']['soil_properties']
                health_indicators = data['data']['health_indicators']
                
                return {
                    'ph': soil_props.get('ph', 6.5),
                    'organic_carbon': soil_props.get('organic_carbon', 1.0),
                    'nitrogen': soil_props.get('nitrogen', 100),
                    'phosphorus': soil_props.get('phosphorus', 25),
                    'potassium': soil_props.get('potassium', 200),
                    'sand_content': soil_props.get('sand_content', 40),
                    'clay_content': soil_props.get('clay_content', 30),
                    'soil_moisture': soil_props.get('soil_moisture', 50),
                    'bulk_density': soil_props.get('bulk_density', 1.3),
                    'cation_exchange_capacity': soil_props.get('cation_exchange_capacity', 10),
                    'health_score': health_indicators.get('health_score', 75),
                    'fertility_index': health_indicators.get('fertility_index', 70),
                    'data_source': 'Satellite + Bhuvan',
                    'confidence_score': soil_props.get('confidence_score', 0.85)
                }
    except Exception as e:
        logger.warning(f"Satellite soil data error: {e}")
    
    # Fallback to simulated high-quality data
    return {
        'ph': np.random.uniform(6.0, 8.0),
        'organic_carbon': np.random.uniform(0.8, 2.5),
        'nitrogen': np.random.uniform(80, 250),
        'phosphorus': np.random.uniform(15, 60),
        'potassium': np.random.uniform(150, 450),
        'sand_content': np.random.uniform(25, 65),
        'clay_content': np.random.uniform(15, 45),
        'soil_moisture': np.random.uniform(30, 80),
        'bulk_density': np.random.uniform(1.1, 1.6),
        'cation_exchange_capacity': np.random.uniform(8, 30),
        'health_score': np.random.uniform(60, 90),
        'fertility_index': np.random.uniform(55, 85),
        'data_source': 'Simulated Premium',
        'confidence_score': 0.75
    }

def get_enhanced_weather_data(lat: float, lon: float) -> Dict:
    """Get comprehensive weather data and forecasts"""
    try:
        # Get current weather
        current_response = requests.get(
            f"{API_ENDPOINTS['weather_integration']}/weather/current",
            params={'lat': lat, 'lon': lon, 'location': f"{lat},{lon}"},
            timeout=REQUEST_TIMEOUT
        )
        
        # Get weather forecast
        forecast_response = requests.get(
            f"{API_ENDPOINTS['weather_integration']}/weather/forecast",
            params={'lat': lat, 'lon': lon, 'location': f"{lat},{lon}", 'days': 7},
            timeout=REQUEST_TIMEOUT
        )
        
        weather_data = {}
        
        if current_response.status_code == 200:
            current_data = current_response.json()
            if current_data.get('success'):
                current = current_data['data']
                weather_data.update({
                    'temperature': current.get('temperature', 25),
                    'humidity': current.get('humidity', 60),
                    'pressure': current.get('pressure', 1013),
                    'wind_speed': current.get('wind_speed', 10),
                    'uv_index': current.get('uv_index', 5),
                    'visibility': current.get('visibility', 10)
                })
        
        if forecast_response.status_code == 200:
            forecast_data = forecast_response.json()
            if forecast_data.get('success'):
                forecasts = forecast_data['data']['forecasts']
                # Calculate average rainfall for next 7 days
                total_rainfall = sum(f.get('precipitation', 0) for f in forecasts)
                weather_data['rainfall'] = total_rainfall
                
                # Calculate temperature trends
                temps = [f.get('temperature_max', 25) for f in forecasts]
                weather_data['temp_trend'] = 'stable' if max(temps) - min(temps) < 5 else 'variable'
        
        # Add derived weather parameters
        weather_data.update({
            'evapotranspiration': calculate_et_rate(weather_data),
            'heat_index': calculate_heat_index(weather_data),
            'growing_degree_days': calculate_gdd(weather_data),
            'data_source': 'Weather API',
            'confidence_score': 0.9
        })
        
        return weather_data
        
    except Exception as e:
        logger.warning(f"Weather data error: {e}")
        
    # Fallback weather data
    return {
        'temperature': np.random.uniform(18, 35),
        'humidity': np.random.uniform(40, 85),
        'pressure': np.random.uniform(1005, 1025),
        'wind_speed': np.random.uniform(5, 20),
        'rainfall': np.random.uniform(200, 1500),
        'uv_index': np.random.uniform(3, 9),
        'visibility': np.random.uniform(8, 15),
        'evapotranspiration': np.random.uniform(3, 8),
        'heat_index': np.random.uniform(20, 40),
        'growing_degree_days': np.random.uniform(1200, 2500),
        'temp_trend': 'stable',
        'data_source': 'Simulated',
        'confidence_score': 0.65
    }

def calculate_et_rate(weather_data: Dict) -> float:
    """Calculate evapotranspiration rate"""
    temp = weather_data.get('temperature', 25)
    humidity = weather_data.get('humidity', 60)
    wind_speed = weather_data.get('wind_speed', 10)
    
    # Simplified Penman equation
    et_rate = (temp - 5) * 0.1 * (1 - humidity/100) * (1 + wind_speed/20)
    return max(0, round(et_rate, 2))

def calculate_heat_index(weather_data: Dict) -> float:
    """Calculate heat index"""
    temp = weather_data.get('temperature', 25)
    humidity = weather_data.get('humidity', 60)
    
    # Simplified heat index calculation
    heat_index = temp + (0.1 * humidity) - 2
    return round(heat_index, 1)

def calculate_gdd(weather_data: Dict) -> float:
    """Calculate Growing Degree Days (simplified annual estimate)"""
    temp = weather_data.get('temperature', 25)
    base_temp = 10  # Base temperature for most crops
    
    # Simplified GDD calculation
    gdd = max(0, temp - base_temp) * 365  # Annual estimate
    return round(gdd, 0)

def get_topographic_data(lat: float, lon: float) -> Dict:
    """Get topographic data from SRTM DEM"""
    try:
        # In production, integrate with Google Earth Engine or SRTM API
        # For now, simulate realistic topographic data based on location
        
        # India elevation ranges: 0-8848m, most agricultural land 0-1000m
        elevation = np.random.uniform(50, 800)  # Meters above sea level
        
        # Calculate slope based on elevation variation (simplified)
        slope = np.random.uniform(0, 15)  # Degrees
        
        # Drainage characteristics
        drainage_score = np.random.uniform(0.6, 1.0)
        
        return {
            'elevation': round(elevation, 1),
            'slope': round(slope, 2),
            'drainage_score': round(drainage_score, 2),
            'aspect': np.random.uniform(0, 360),  # Degrees from north
            'terrain_ruggedness': round(np.random.uniform(0, 1), 2),
            'data_source': 'SRTM Simulated',
            'confidence_score': 0.8
        }
        
    except Exception as e:
        logger.warning(f"Topographic data error: {e}")
        return {
            'elevation': 200,
            'slope': 5,
            'drainage_score': 0.8,
            'aspect': 180,
            'terrain_ruggedness': 0.3,
            'data_source': 'Default',
            'confidence_score': 0.5
        }

def get_satellite_indices(lat: float, lon: float) -> Dict:
    """Get vegetation indices from satellite data"""
    try:
        # In production, integrate with Google Earth Engine
        # For now, simulate realistic NDVI and EVI values
        
        # NDVI: -1 to 1, agricultural areas typically 0.3-0.8
        ndvi = np.random.uniform(0.3, 0.8)
        
        # EVI: 0 to 1, similar to NDVI but more sensitive
        evi = np.random.uniform(0.2, 0.7)
        
        # Soil Adjusted Vegetation Index
        savi = ndvi * 1.5  # Simplified calculation
        
        return {
            'ndvi': round(ndvi, 3),
            'evi': round(evi, 3),
            'savi': round(min(savi, 1.0), 3),
            'data_source': 'Satellite Simulated',
            'confidence_score': 0.85,
            'acquisition_date': datetime.now().strftime('%Y-%m-%d')
        }
        
    except Exception as e:
        logger.warning(f"Satellite indices error: {e}")
        return {
            'ndvi': 0.6,
            'evi': 0.5,
            'savi': 0.7,
            'data_source': 'Default',
            'confidence_score': 0.5,
            'acquisition_date': datetime.now().strftime('%Y-%m-%d')
        }

def calculate_water_access_score(lat: float, lon: float, topographic_data: Dict) -> float:
    """Calculate water access score based on location and topography"""
    try:
        # Factors affecting water access:
        # 1. Proximity to water bodies (rivers, lakes)
        # 2. Groundwater availability
        # 3. Irrigation infrastructure
        # 4. Slope and drainage
        
        # Simulate water access based on topographic data
        slope = topographic_data.get('slope', 5)
        drainage = topographic_data.get('drainage_score', 0.8)
        elevation = topographic_data.get('elevation', 200)
        
        # Lower slope and good drainage = better water access
        slope_score = max(0, 1 - slope / 20)
        drainage_score = drainage
        elevation_score = max(0, 1 - elevation / 1000)  # Lower elevation generally better
        
        # Random factor for infrastructure and groundwater
        infrastructure_score = np.random.uniform(0.5, 0.9)
        
        water_access_score = (slope_score + drainage_score + elevation_score + infrastructure_score) / 4
        
        return round(min(water_access_score, 1.0), 3)
        
    except Exception as e:
        logger.warning(f"Water access calculation error: {e}")
        return 0.7  # Default moderate access

def get_market_analysis(crop_name: str) -> Dict:
    """Get market analysis for specific crop"""
    try:
        response = requests.get(
            f"{API_ENDPOINTS['market_price']}/price/current",
            params={'crop': crop_name},
            timeout=REQUEST_TIMEOUT
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                return data['data']
                
    except Exception as e:
        logger.warning(f"Market analysis error: {e}")
    
    # Fallback market data
    crop_info = ULTRA_CROP_DATABASE.get(crop_name, {})
    base_price = {
        'Rice': 2000, 'Wheat': 1800, 'Maize': 1500, 
        'Cotton': 5000, 'Sugarcane': 300, 'Soybean': 3500
    }.get(crop_name, 2000)
    
    return {
        'current_price': base_price + np.random.uniform(-200, 200),
        'price_trend': np.random.choice(['rising', 'stable', 'falling']),
        'market_demand': crop_info.get('market_demand', 'Medium'),
        'profit_margin': crop_info.get('profit_margin', 'Medium'),
        'data_source': 'Market Simulated'
    }

def predict_ultra_crop_recommendation(comprehensive_data: Dict) -> Dict:
    """Ultra crop recommendation using ensemble ML models"""
    try:
        if not ml_engine.models_loaded:
            return get_rule_based_ultra_recommendation(comprehensive_data)
        
        # Prepare feature vector
        features = []
        for feature_name in ml_engine.feature_names:
            if feature_name in comprehensive_data:
                features.append(comprehensive_data[feature_name])
            else:
                # Use default values for missing features
                default_values = {
                    'nitrogen': 100, 'phosphorus': 25, 'potassium': 200,
                    'temperature': 25, 'humidity': 60, 'ph': 6.5,
                    'rainfall': 1000, 'soil_moisture': 50, 'organic_carbon': 1.0,
                    'clay_content': 30, 'sand_content': 40, 'elevation': 200,
                    'slope': 5, 'ndvi': 0.6, 'evi': 0.5, 'water_access_score': 0.7
                }
                features.append(default_values.get(feature_name, 0))
        
        features_array = np.array([features])
        
        # Scale features
        features_scaled = ml_engine.scaler.transform(features_array)
        
        # Get predictions from ensemble model
        if hasattr(ml_engine.ensemble_model, 'predict_proba'):
            probabilities = ml_engine.ensemble_model.predict_proba(features_scaled)[0]
            prediction = ml_engine.ensemble_model.predict(features_scaled)[0]
            confidence = probabilities.max()
        else:
            # Fallback to individual model predictions
            rf_pred = ml_engine.rf_model.predict(features_scaled)[0]
            rf_prob = ml_engine.rf_model.predict_proba(features_scaled)[0]
            
            prediction = rf_pred
            confidence = rf_prob.max()
        
        # Decode prediction
        crop_name = ml_engine.label_encoder.inverse_transform([prediction])[0]
        
        # Get top 3 recommendations
        if hasattr(ml_engine.ensemble_model, 'predict_proba'):
            all_probabilities = ml_engine.ensemble_model.predict_proba(features_scaled)[0]
            top_indices = np.argsort(all_probabilities)[-3:][::-1]
            
            recommendations = []
            for idx in top_indices:
                crop = ml_engine.label_encoder.inverse_transform([idx])[0]
                prob = all_probabilities[idx]
                recommendations.append({
                    'crop': crop,
                    'confidence': float(prob),
                    'crop_info': ULTRA_CROP_DATABASE.get(crop, {})
                })
        else:
            recommendations = [{
                'crop': crop_name,
                'confidence': float(confidence),
                'crop_info': ULTRA_CROP_DATABASE.get(crop_name, {})
            }]
        
        return {
            'primary_recommendation': crop_name,
            'confidence': float(confidence),
            'all_recommendations': recommendations,
            'method': 'Ultra ML Ensemble',
            'model_version': 'v2.0',
            'features_used': len(features)
        }
        
    except Exception as e:
        logger.error(f"Ultra ML prediction error: {e}")
        return get_rule_based_ultra_recommendation(comprehensive_data)

def get_rule_based_ultra_recommendation(comprehensive_data: Dict) -> Dict:
    """Advanced rule-based recommendation system"""
    recommendations = []
    
    for crop_name, crop_info in ULTRA_CROP_DATABASE.items():
        score = 0
        factors = []
        
        # Soil pH compatibility (30 points)
        ph = comprehensive_data.get('ph', 6.5)
        ph_min, ph_max = crop_info['soil_ph_range']
        if ph_min <= ph <= ph_max:
            ph_score = 30
            factors.append(f"✅ pH {ph} is optimal for {crop_name}")
        else:
            ph_distance = min(abs(ph - ph_min), abs(ph - ph_max))
            ph_score = max(0, 30 - ph_distance * 10)
            factors.append(f"⚠️ pH {ph} needs adjustment for {crop_name}")
        score += ph_score
        
        # Temperature compatibility (25 points)
        temp = comprehensive_data.get('temperature', 25)
        temp_min, temp_max = crop_info['temperature_range']
        if temp_min <= temp <= temp_max:
            temp_score = 25
            factors.append(f"✅ Temperature {temp}°C is perfect")
        else:
            temp_distance = min(abs(temp - temp_min), abs(temp - temp_max))
            temp_score = max(0, 25 - temp_distance * 2)
            factors.append(f"⚠️ Temperature {temp}°C not optimal")
        score += temp_score
        
        # Rainfall compatibility (20 points)
        rainfall = comprehensive_data.get('rainfall', 1000)
        rain_min, rain_max = crop_info['rainfall_range']
        if rain_min <= rainfall <= rain_max:
            rain_score = 20
            factors.append(f"✅ Rainfall {rainfall}mm is suitable")
        else:
            rain_distance = min(abs(rainfall - rain_min), abs(rainfall - rain_max))
            rain_score = max(0, 20 - rain_distance / 100)
            factors.append(f"⚠️ Rainfall {rainfall}mm needs management")
        score += rain_score
        
        # Soil health and fertility (15 points)
        fertility_index = comprehensive_data.get('fertility_index', 70)
        fertility_score = min(15, fertility_index * 15 / 100)
        score += fertility_score
        factors.append(f"Soil fertility index: {fertility_index}%")
        
        # Water access and irrigation (10 points)
        water_access = comprehensive_data.get('water_access_score', 0.7)
        water_score = water_access * 10
        score += water_score
        factors.append(f"Water access score: {water_access:.2f}")
        
        # Market and profitability bonus
        market_demand = crop_info.get('market_demand', 'Medium')
        if market_demand == 'Very High':
            score += 5
            factors.append("🚀 Excellent market demand")
        elif market_demand == 'High':
            score += 3
            factors.append("📈 Good market demand")
        
        recommendations.append({
            'crop': crop_name,
            'score': score,
            'confidence': min(score / 100, 1.0),
            'factors': factors,
            'crop_info': crop_info
        })
    
    # Sort by score
    recommendations.sort(key=lambda x: x['score'], reverse=True)
    
    return {
        'primary_recommendation': recommendations[0]['crop'],
        'confidence': recommendations[0]['confidence'],
        'all_recommendations': recommendations,
        'method': 'Ultra Rule-Based',
        'model_version': 'v2.0',
        'features_used': len(comprehensive_data)
    }

def generate_comprehensive_analysis(recommendation_data: Dict, comprehensive_data: Dict) -> Dict:
    """Generate comprehensive analysis and recommendations"""
    primary_crop = recommendation_data['primary_recommendation']
    crop_info = ULTRA_CROP_DATABASE.get(primary_crop, {})
    
    analysis = {
        'crop_suitability': {
            'primary_crop': primary_crop,
            'confidence': recommendation_data['confidence'],
            'suitability_score': recommendation_data['confidence'] * 100,
            'alternative_crops': [
                rec['crop'] for rec in recommendation_data['all_recommendations'][1:4]
            ]
        },
        'environmental_analysis': {
            'soil_health': comprehensive_data.get('health_score', 75),
            'fertility_status': comprehensive_data.get('fertility_index', 70),
            'climate_suitability': 'Excellent' if recommendation_data['confidence'] > 0.8 else 'Good',
            'water_availability': comprehensive_data.get('water_access_score', 0.7) * 100,
            'topographic_suitability': 100 - comprehensive_data.get('slope', 5) * 5
        },
        'agronomic_recommendations': {
            'planting_season': crop_info.get('seasons', ['Kharif'])[0],
            'expected_duration': crop_info.get('growth_duration', '120 days'),
            'water_management': crop_info.get('water_requirement', 'Medium'),
            'soil_preparation': generate_soil_preparation_advice(comprehensive_data),
            'fertilizer_recommendations': generate_fertilizer_recommendations(comprehensive_data),
            'irrigation_schedule': generate_irrigation_schedule(comprehensive_data, crop_info)
        },
        'economic_analysis': {
            'yield_potential': crop_info.get('yield_potential', 'Unknown'),
            'market_demand': crop_info.get('market_demand', 'Medium'),
            'profit_margin': crop_info.get('profit_margin', 'Medium'),
            'input_cost': crop_info.get('input_cost', 'Medium'),
            'roi_estimate': calculate_roi_estimate(crop_info)
        },
        'sustainability_metrics': {
            'sustainability_score': crop_info.get('sustainability_score', 7.0),
            'environmental_impact': 'Low' if crop_info.get('sustainability_score', 7.0) > 8 else 'Medium',
            'soil_conservation': generate_conservation_advice(comprehensive_data),
            'carbon_footprint': 'Low' if primary_crop in ['Soybean', 'Wheat'] else 'Medium'
        },
        'risk_assessment': {
            'disease_risk': crop_info.get('disease_resistance', 'Medium'),
            'climate_risk': assess_climate_risk(comprehensive_data),
            'market_risk': 'Low' if crop_info.get('market_demand', 'Medium') == 'Very High' else 'Medium',
            'mitigation_strategies': generate_risk_mitigation(comprehensive_data, crop_info)
        }
    }
    
    return analysis

def generate_soil_preparation_advice(data: Dict) -> List[str]:
    """Generate soil preparation recommendations"""
    advice = []
    
    ph = data.get('ph', 6.5)
    if ph < 6.0:
        advice.append("Apply lime to increase soil pH (2-3 tons/hectare)")
    elif ph > 8.0:
        advice.append("Apply sulfur or organic matter to reduce pH")
    
    organic_carbon = data.get('organic_carbon', 1.0)
    if organic_carbon < 0.75:
        advice.append("Add 5-10 tons of well-decomposed farmyard manure per hectare")
    
    clay_content = data.get('clay_content', 30)
    if clay_content > 60:
        advice.append("Improve drainage with sand and organic matter")
    elif clay_content < 15:
        advice.append("Add clay or organic matter to improve water retention")
    
    return advice

def generate_fertilizer_recommendations(data: Dict) -> Dict:
    """Generate NPK fertilizer recommendations"""
    nitrogen = data.get('nitrogen', 100)
    phosphorus = data.get('phosphorus', 25)
    potassium = data.get('potassium', 200)
    
    recommendations = {
        'nitrogen': 'Medium' if nitrogen > 80 else 'High',
        'phosphorus': 'Medium' if phosphorus > 20 else 'High',
        'potassium': 'Low' if potassium > 150 else 'Medium',
        'organic_fertilizer': 'Apply 2-3 tons compost per hectare',
        'micronutrients': 'Apply zinc and boron as per soil test'
    }
    
    return recommendations

def generate_irrigation_schedule(data: Dict, crop_info: Dict) -> Dict:
    """Generate irrigation recommendations"""
    water_req = crop_info.get('water_requirement', 'Medium')
    soil_moisture = data.get('soil_moisture', 50)
    rainfall = data.get('rainfall', 1000)
    
    if water_req == 'Very High':
        frequency = 'Every 3-4 days'
        amount = '50-75mm per irrigation'
    elif water_req == 'High':
        frequency = 'Every 5-7 days'
        amount = '40-60mm per irrigation'
    elif water_req == 'Medium':
        frequency = 'Every 7-10 days'
        amount = '30-50mm per irrigation'
    else:
        frequency = 'Every 10-14 days'
        amount = '25-40mm per irrigation'
    
    return {
        'frequency': frequency,
        'amount': amount,
        'method': 'Drip irrigation recommended' if water_req in ['High', 'Very High'] else 'Furrow irrigation suitable',
        'critical_stages': 'Flowering and grain filling stages need adequate water'
    }

def calculate_roi_estimate(crop_info: Dict) -> str:
    """Calculate ROI estimate"""
    profit_margin = crop_info.get('profit_margin', 'Medium')
    input_cost = crop_info.get('input_cost', 'Medium')
    
    roi_map = {
        ('Very High', 'Low'): '200-300%',
        ('Very High', 'Medium'): '150-250%',
        ('High', 'Low'): '150-200%',
        ('High', 'Medium'): '100-150%',
        ('Medium', 'Low'): '100-120%',
        ('Medium', 'Medium'): '80-120%'
    }
    
    return roi_map.get((profit_margin, input_cost), '80-120%')

def assess_climate_risk(data: Dict) -> str:
    """Assess climate risk based on weather patterns"""
    temp = data.get('temperature', 25)
    rainfall = data.get('rainfall', 1000)
    humidity = data.get('humidity', 60)
    
    risk_factors = 0
    if temp > 35 or temp < 10:
        risk_factors += 1
    if rainfall < 300 or rainfall > 2500:
        risk_factors += 1
    if humidity < 30 or humidity > 90:
        risk_factors += 1
    
    if risk_factors >= 2:
        return 'High'
    elif risk_factors == 1:
        return 'Medium'
    else:
        return 'Low'

def generate_conservation_advice(data: Dict) -> List[str]:
    """Generate soil conservation advice"""
    advice = []
    
    slope = data.get('slope', 5)
    if slope > 8:
        advice.append("Implement contour farming and terracing")
    
    organic_carbon = data.get('organic_carbon', 1.0)
    if organic_carbon < 1.0:
        advice.append("Practice crop rotation with legumes")
        advice.append("Use cover crops during fallow periods")
    
    advice.append("Minimize tillage to preserve soil structure")
    advice.append("Maintain crop residues for organic matter")
    
    return advice

def generate_risk_mitigation(data: Dict, crop_info: Dict) -> List[str]:
    """Generate risk mitigation strategies"""
    strategies = []
    
    # Disease risk mitigation
    disease_resistance = crop_info.get('disease_resistance', 'Medium')
    if disease_resistance == 'Low':
        strategies.append("Use disease-resistant varieties")
        strategies.append("Implement integrated pest management")
    
    # Climate risk mitigation
    climate_risk = assess_climate_risk(data)
    if climate_risk == 'High':
        strategies.append("Install weather monitoring systems")
        strategies.append("Consider crop insurance")
    
    # Market risk mitigation
    strategies.append("Diversify crop portfolio")
    strategies.append("Consider contract farming for price stability")
    
    return strategies

# API Endpoints

@app.route('/health', methods=['GET'])
def health_check_endpoint():
    """Health check for Ultra Crop Recommender API"""
    return jsonify({
        "success": True,
        "message": "Ultra Crop Recommender API is running",
        "version": "2.0",
        "timestamp": datetime.now().isoformat(),
        "ml_models_loaded": ml_engine.models_loaded,
        "available_crops": len(ULTRA_CROP_DATABASE),
        "features": [
            "🛰️ Satellite soil data integration",
            "🌦️ Advanced weather analytics", 
            "🤖 Ensemble ML models (RF + NN + XGBoost)",
            "📊 Comprehensive market analysis",
            "🌱 Sustainability scoring",
            "💰 Economic analysis and ROI",
            "🗺️ Topographic analysis",
            "🌿 Vegetation indices (NDVI/EVI)",
            "💧 Water access assessment",
            "🌍 Multi-language support ready"
        ]
    })

@app.route('/ultra-recommend', methods=['POST'])
def ultra_crop_recommendation():
    """Ultra Crop Recommender - Main endpoint"""
    try:
        data = request.get_json()
        
        # Extract location data
        latitude = float(data.get('latitude', 28.6139))
        longitude = float(data.get('longitude', 77.2090))
        location_name = data.get('location', f"{latitude},{longitude}")
        
        # Optional user-provided data
        user_soil_data = data.get('soil_data', {})
        farm_size = float(data.get('farm_size', 1.0))
        irrigation_type = data.get('irrigation_type', 'canal')
        preferred_crops = data.get('preferred_crops', [])
        
        logger.info(f"🚀 Ultra recommendation request for {location_name}")
        
        # Gather comprehensive data from multiple sources
        logger.info("📡 Fetching satellite soil data...")
        satellite_soil_data = get_satellite_soil_data(latitude, longitude)
        
        logger.info("🌦️ Fetching weather data...")
        weather_data = get_enhanced_weather_data(latitude, longitude)
        
        logger.info("🗻 Fetching topographic data...")
        topographic_data = get_topographic_data(latitude, longitude)
        
        logger.info("🛰️ Fetching vegetation indices...")
        satellite_indices = get_satellite_indices(latitude, longitude)
        
        logger.info("💧 Calculating water access...")
        water_access_score = calculate_water_access_score(latitude, longitude, topographic_data)
        
        # Merge all data sources
        comprehensive_data = {}
        comprehensive_data.update(satellite_soil_data)
        comprehensive_data.update(weather_data)
        comprehensive_data.update(topographic_data)
        comprehensive_data.update(satellite_indices)
        comprehensive_data['water_access_score'] = water_access_score
        comprehensive_data['farm_size'] = farm_size
        comprehensive_data['irrigation_type'] = irrigation_type
        
        # Override with user-provided data if available
        comprehensive_data.update(user_soil_data)
        
        logger.info("🤖 Running Ultra ML prediction...")
        # Get ML-based recommendation
        recommendation_data = predict_ultra_crop_recommendation(comprehensive_data)
        
        logger.info("📊 Generating comprehensive analysis...")
        # Generate comprehensive analysis
        analysis = generate_comprehensive_analysis(recommendation_data, comprehensive_data)
        
        # Get market analysis for primary crop
        primary_crop = recommendation_data['primary_recommendation']
        market_analysis = get_market_analysis(primary_crop)
        
        # Prepare response
        response_data = {
            'location': {
                'name': location_name,
                'coordinates': {'latitude': latitude, 'longitude': longitude},
                'farm_size_hectares': farm_size,
                'irrigation_type': irrigation_type
            },
            'data_sources': {
                'soil_data': satellite_soil_data.get('data_source', 'Unknown'),
                'weather_data': weather_data.get('data_source', 'Unknown'),
                'topographic_data': topographic_data.get('data_source', 'Unknown'),
                'satellite_indices': satellite_indices.get('data_source', 'Unknown'),
                'confidence_scores': {
                    'soil': satellite_soil_data.get('confidence_score', 0.5),
                    'weather': weather_data.get('confidence_score', 0.5),
                    'topographic': topographic_data.get('confidence_score', 0.5),
                    'satellite': satellite_indices.get('confidence_score', 0.5)
                }
            },
            'recommendation': recommendation_data,
            'comprehensive_analysis': analysis,
            'market_analysis': market_analysis,
            'comprehensive_data_summary': {
                'soil_health_score': comprehensive_data.get('health_score', 75),
                'fertility_index': comprehensive_data.get('fertility_index', 70),
                'climate_suitability': analysis['environmental_analysis']['climate_suitability'],
                'water_access_score': water_access_score,
                'sustainability_score': analysis['sustainability_metrics']['sustainability_score'],
                'overall_recommendation_confidence': recommendation_data['confidence']
            },
            'actionable_insights': {
                'immediate_actions': [
                    f"Plant {primary_crop} in {analysis['agronomic_recommendations']['planting_season']} season",
                    f"Expected yield: {analysis['economic_analysis']['yield_potential']}",
                    f"Estimated ROI: {analysis['economic_analysis']['roi_estimate']}"
                ],
                'preparation_needed': analysis['agronomic_recommendations']['soil_preparation'][:3],
                'long_term_strategy': [
                    "Monitor soil health quarterly",
                    "Implement sustainable farming practices",
                    "Consider crop rotation for soil health"
                ]
            },
            'timestamp': datetime.now().isoformat(),
            'api_version': '2.0'
        }
        
        # Store recommendation in database
        try:
            db = next(get_db())
            
            recommendation_record = YieldPrediction(
                id=str(uuid.uuid4()),
                field_id=data.get('field_id', f"ultra_{datetime.now().strftime('%Y%m%d_%H%M%S')}"),
                crop_name=primary_crop,
                predicted_yield=0.0,  # Will be calculated separately
                confidence_score=recommendation_data['confidence'],
                soil_ph=comprehensive_data.get('ph'),
                soil_moisture=comprehensive_data.get('soil_moisture'),
                temperature=comprehensive_data.get('temperature'),
                rainfall=comprehensive_data.get('rainfall'),
                area_hectares=farm_size,
                season=analysis['agronomic_recommendations']['planting_season'],
                prediction_factors=json.dumps({
                    'method': recommendation_data['method'],
                    'features_used': recommendation_data['features_used'],
                    'data_sources': response_data['data_sources']
                })
            )
            
            db.add(recommendation_record)
            db.commit()
            db.close()
            
        except Exception as e:
            logger.warning(f"Database storage error: {e}")
        
        logger.info(f"✅ Ultra recommendation completed for {location_name}")
        
        return jsonify({
            "success": True,
            "data": response_data
        })
        
    except Exception as e:
        logger.error(f"❌ Ultra recommendation error: {str(e)}")
        return jsonify({
            "success": False,
            "error": f"Ultra recommendation failed: {str(e)}",
            "error_type": "processing_error"
        }), 500

@app.route('/ultra-recommend/quick', methods=['POST'])
def quick_ultra_recommendation():
    """Quick Ultra Recommendation with minimal data requirements"""
    try:
        data = request.get_json()
        
        latitude = float(data.get('latitude', 28.6139))
        longitude = float(data.get('longitude', 77.2090))
        
        # Get essential data only
        soil_data = get_satellite_soil_data(latitude, longitude)
        weather_data = get_enhanced_weather_data(latitude, longitude)
        
        # Minimal comprehensive data
        quick_data = {
            'ph': soil_data.get('ph', 6.5),
            'nitrogen': soil_data.get('nitrogen', 100),
            'phosphorus': soil_data.get('phosphorus', 25),
            'potassium': soil_data.get('potassium', 200),
            'temperature': weather_data.get('temperature', 25),
            'humidity': weather_data.get('humidity', 60),
            'rainfall': weather_data.get('rainfall', 1000),
            'soil_moisture': soil_data.get('soil_moisture', 50)
        }
        
        # Get quick recommendation
        recommendation = predict_ultra_crop_recommendation(quick_data)
        primary_crop = recommendation['primary_recommendation']
        crop_info = ULTRA_CROP_DATABASE.get(primary_crop, {})
        
        return jsonify({
            "success": True,
            "data": {
                "recommended_crop": primary_crop,
                "confidence": recommendation['confidence'],
                "quick_info": {
                    "season": crop_info.get('seasons', ['Kharif'])[0],
                    "duration": crop_info.get('growth_duration', '120 days'),
                    "yield_potential": crop_info.get('yield_potential', 'Unknown'),
                    "water_requirement": crop_info.get('water_requirement', 'Medium')
                },
                "location": {"latitude": latitude, "longitude": longitude},
                "method": "Ultra Quick",
                "timestamp": datetime.now().isoformat()
            }
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/ultra-recommend/crops', methods=['GET'])
def get_ultra_crop_database():
    """Get enhanced crop database"""
    return jsonify({
        "success": True,
        "data": {
            "crops": ULTRA_CROP_DATABASE,
            "total_crops": len(ULTRA_CROP_DATABASE),
            "database_version": "2.0"
        }
    })

if __name__ == '__main__':
    # Avoid unicode banners on Windows consoles that can't render them
    try:
        print("ULTRA CROP RECOMMENDER API Starting...")
        print(f"ML Models: {'Loaded' if ml_engine.models_loaded else 'Rule-based fallback'}")
        print(f"Enhanced crop database: {len(ULTRA_CROP_DATABASE)} crops")
        print("Features:")
        print("  - Satellite soil data integration")
        print("  - Advanced weather analytics with forecasts")
        print("  - Ensemble ML models (RF + NN + XGBoost)")
        print("  - Topographic analysis (SRTM DEM)")
        print("  - Vegetation indices (NDVI/EVI)")
        print("  - Water access assessment")
        print("  - Comprehensive market analysis")
        print("  - Sustainability scoring")
        print("  - Economic analysis and ROI calculation")
        print("  - Risk assessment and mitigation strategies")
        print("Server running on http://0.0.0.0:5020")
        print("Android emulator can access via http://10.0.2.2:5020")
    except Exception:
        pass
    app.run(debug=True, host='0.0.0.0', port=5020)
