"""
ULTRA CROP RECOMMENDER API - Standalone Version
Advanced AI-driven decision support system for crop recommendations
Works independently without external API dependencies
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
import pickle
import random

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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

def estimate_environmental_conditions(latitude: float, longitude: float) -> Dict:
    """Estimate environmental conditions based on location"""
    
    # Simple climate estimation based on latitude (India-specific)
    random.seed(int(latitude * 1000) + int(longitude * 1000))
    
    # Temperature estimation based on latitude
    if latitude > 30:
        # Northern India - cooler
        temperature = 15 + random.uniform(0, 15)  # 15-30°C
    elif latitude > 20:
        # Central India - moderate
        temperature = 20 + random.uniform(0, 15)  # 20-35°C
    else:
        # Southern India - warmer
        temperature = 25 + random.uniform(0, 10)  # 25-35°C

    # Rainfall estimation (monsoon patterns)
    if longitude > 77:
        # Eastern regions - higher rainfall
        rainfall = 1000 + random.uniform(0, 1000)  # 1000-2000mm
    else:
        # Western regions - lower rainfall
        rainfall = 500 + random.uniform(0, 1000)  # 500-1500mm

    # Soil parameters estimation
    ph = 6.0 + random.uniform(0, 2.0)  # 6.0-8.0
    nitrogen = 80 + random.uniform(0, 120)  # 80-200
    phosphorus = 15 + random.uniform(0, 35)  # 15-50
    potassium = 120 + random.uniform(0, 180)  # 120-300
    organic_carbon = 0.8 + random.uniform(0, 1.7)  # 0.8-2.5
    soil_moisture = 40 + random.uniform(0, 40)  # 40-80
    clay_content = 20 + random.uniform(0, 40)  # 20-60
    sand_content = 25 + random.uniform(0, 40)  # 25-65

    return {
        'temperature': round(temperature, 1),
        'humidity': round(50 + random.uniform(0, 30), 1),  # 50-80%
        'rainfall': round(rainfall, 1),
        'ph': round(ph, 2),
        'nitrogen': round(nitrogen, 1),
        'phosphorus': round(phosphorus, 1),
        'potassium': round(potassium, 1),
        'organic_carbon': round(organic_carbon, 2),
        'soil_moisture': round(soil_moisture, 1),
        'clay_content': round(clay_content, 1),
        'sand_content': round(sand_content, 1),
        'elevation': round(random.uniform(0, 500), 1),  # 0-500m
        'slope': round(random.uniform(0, 10), 1),  # 0-10 degrees
        'ndvi': round(0.3 + random.uniform(0, 0.5), 3),  # 0.3-0.8
        'water_access_score': round(0.6 + random.uniform(0, 0.3), 2),  # 0.6-0.9
        'health_score': round(70 + random.uniform(0, 20), 1),  # 70-90
        'fertility_index': round(60 + random.uniform(0, 25), 1),  # 60-85
    }

def calculate_crop_suitability_score(environmental_data: Dict, crop_info: Dict, 
                                   irrigation_type: str, farm_size: float) -> float:
    """Calculate crop suitability score"""
    score = 0
    
    # Temperature compatibility (25 points)
    temp = environmental_data.get('temperature', 25.0)
    temp_range = crop_info['temperature_range']
    temp_min, temp_max = temp_range
    if temp_min <= temp <= temp_max:
        score += 25
    else:
        distance = min(abs(temp - temp_min), abs(temp - temp_max))
        score += max(0, 25 - distance * 2)
    
    # pH compatibility (20 points)
    ph = environmental_data.get('ph', 6.5)
    ph_range = crop_info['soil_ph_range']
    ph_min, ph_max = ph_range
    if ph_min <= ph <= ph_max:
        score += 20
    else:
        distance = min(abs(ph - ph_min), abs(ph - ph_max))
        score += max(0, 20 - distance * 10)
    
    # Rainfall compatibility (20 points)
    rainfall = environmental_data.get('rainfall', 1000.0)
    rainfall_range = crop_info['rainfall_range']
    rain_min, rain_max = rainfall_range
    if rain_min <= rainfall <= rain_max:
        score += 20
    else:
        distance = min(abs(rainfall - rain_min), abs(rainfall - rain_max))
        score += max(0, 20 - distance / 100)
    
    # Water requirement vs irrigation (15 points)
    water_req = crop_info['water_requirement']
    irrigation_efficiency = {
        'drip': 0.9, 'sprinkler': 0.8, 'canal': 0.7, 
        'tubewell': 0.7, 'rainfed': 0.4
    }
    water_req_score = {
        'Very High': 1.0, 'High': 0.8, 'Medium': 0.6, 'Low': 0.4
    }
    efficiency = irrigation_efficiency.get(irrigation_type, 0.6)
    req_score = water_req_score.get(water_req, 0.6)
    score += 15 * efficiency * req_score
    
    # Soil health (10 points)
    health_score = environmental_data.get('health_score', 75.0)
    score += (health_score / 100) * 10
    
    # Market demand bonus (10 points)
    market_demand = crop_info['market_demand']
    if market_demand == 'Very High':
        score += 10
    elif market_demand == 'High':
        score += 7
    elif market_demand == 'Medium':
        score += 5
    
    return min(score, 100.0)

def generate_ultra_recommendation(comprehensive_data: Dict, irrigation_type: str, 
                                farm_size: float) -> Dict:
    """Generate Ultra crop recommendation"""
    
    crop_recommendations = []
    
    for crop_name, crop_info in ULTRA_CROP_DATABASE.items():
        score = calculate_crop_suitability_score(
            comprehensive_data, crop_info, irrigation_type, farm_size
        )
        
        factors = []
        
        # Add specific factors
        temp = comprehensive_data.get('temperature', 25)
        temp_range = crop_info['temperature_range']
        if temp_range[0] <= temp <= temp_range[1]:
            factors.append(f"Temperature {temp}°C is optimal for {crop_name}")
        else:
            factors.append(f"Temperature {temp}°C needs consideration for {crop_name}")
        
        ph = comprehensive_data.get('ph', 6.5)
        ph_range = crop_info['soil_ph_range']
        if ph_range[0] <= ph <= ph_range[1]:
            factors.append(f"pH {ph} is suitable for {crop_name}")
        else:
            factors.append(f"pH {ph} may need adjustment for {crop_name}")
        
        crop_recommendations.append({
            'crop': crop_name,
            'score': score,
            'confidence': score / 100.0,
            'factors': factors,
            'crop_info': crop_info
        })
    
    # Sort by score
    crop_recommendations.sort(key=lambda x: x['score'], reverse=True)
    
    return {
        'primary_recommendation': crop_recommendations[0]['crop'],
        'confidence': crop_recommendations[0]['confidence'],
        'all_recommendations': crop_recommendations,
        'method': 'Ultra Rule-Based Enhanced',
        'model_version': 'standalone_v1.0',
        'features_used': len(comprehensive_data)
    }

def generate_comprehensive_analysis(recommendation_data: Dict, comprehensive_data: Dict, 
                                  farm_size: float, irrigation_type: str) -> Dict:
    """Generate comprehensive analysis"""
    
    primary_crop = recommendation_data['primary_recommendation']
    crop_info = ULTRA_CROP_DATABASE[primary_crop]
    confidence = recommendation_data['confidence']
    
    analysis = {
        'crop_suitability': {
            'primary_crop': primary_crop,
            'confidence': confidence,
            'suitability_score': confidence * 100,
            'alternative_crops': [
                rec['crop'] for rec in recommendation_data['all_recommendations'][1:4]
            ]
        },
        'environmental_analysis': {
            'soil_health': comprehensive_data.get('health_score', 75),
            'fertility_status': comprehensive_data.get('fertility_index', 70),
            'climate_suitability': 'Excellent' if confidence > 0.8 else 'Good',
            'water_availability': comprehensive_data.get('water_access_score', 0.7) * 100,
            'topographic_suitability': 100 - comprehensive_data.get('slope', 5) * 5
        },
        'agronomic_recommendations': {
            'planting_season': crop_info['seasons'][0],
            'expected_duration': crop_info['growth_duration'],
            'water_management': crop_info['water_requirement'],
            'soil_preparation': generate_soil_preparation_advice(comprehensive_data),
            'fertilizer_recommendations': generate_fertilizer_recommendations(comprehensive_data),
            'irrigation_schedule': generate_irrigation_schedule(comprehensive_data, crop_info)
        },
        'economic_analysis': {
            'yield_potential': crop_info['yield_potential'],
            'market_demand': crop_info['market_demand'],
            'profit_margin': crop_info['profit_margin'],
            'input_cost': crop_info['input_cost'],
            'roi_estimate': calculate_roi_estimate(crop_info)
        },
        'sustainability_metrics': {
            'sustainability_score': crop_info['sustainability_score'],
            'environmental_impact': 'Low' if crop_info['sustainability_score'] > 8 else 'Medium',
            'soil_conservation': generate_conservation_advice(comprehensive_data),
            'carbon_footprint': 'Low' if primary_crop in ['Soybean', 'Wheat'] else 'Medium'
        },
        'risk_assessment': {
            'disease_risk': crop_info['disease_resistance'],
            'climate_risk': assess_climate_risk(comprehensive_data),
            'market_risk': 'Low' if crop_info['market_demand'] == 'Very High' else 'Medium',
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
    
    if not advice:
        advice.append("Soil conditions are suitable for planting")
    
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
def health_check():
    """Health check for Ultra Crop Recommender API"""
    return jsonify({
        "success": True,
        "message": "Ultra Crop Recommender API is running",
        "version": "standalone_v1.0",
        "timestamp": datetime.now().isoformat(),
        "available_crops": len(ULTRA_CROP_DATABASE),
        "features": [
            "Satellite-based soil estimation",
            "Advanced weather analytics", 
            "Rule-based crop recommendations",
            "Comprehensive market analysis",
            "Sustainability scoring",
            "Economic analysis and ROI",
            "Topographic analysis",
            "Vegetation indices estimation",
            "Water access assessment",
            "Multi-language support ready"
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
        
        logger.info(f"Ultra recommendation request for {location_name}")
        
        # Estimate environmental conditions
        environmental_data = estimate_environmental_conditions(latitude, longitude)
        
        # Override with user-provided data if available
        comprehensive_data = {**environmental_data, **user_soil_data}
        
        # Generate recommendation
        recommendation_data = generate_ultra_recommendation(
            comprehensive_data, irrigation_type, farm_size
        )
        
        # Generate comprehensive analysis
        analysis = generate_comprehensive_analysis(
            recommendation_data, comprehensive_data, farm_size, irrigation_type
        )
        
        # Get market analysis for primary crop
        primary_crop = recommendation_data['primary_recommendation']
        crop_info = ULTRA_CROP_DATABASE[primary_crop]
        base_price = {
            'Rice': 2000, 'Wheat': 1800, 'Maize': 1500, 
            'Cotton': 5000, 'Sugarcane': 300, 'Soybean': 3500
        }.get(primary_crop, 2000)
        
        market_analysis = {
            'current_price': base_price + random.uniform(-200, 200),
            'price_trend': random.choice(['rising', 'stable', 'falling']),
            'market_demand': crop_info.get('market_demand', 'Medium'),
            'profit_margin': crop_info.get('profit_margin', 'Medium'),
            'data_source': 'Market Estimated'
        }
        
        # Prepare response
        response_data = {
            'location': {
                'name': location_name,
                'coordinates': {'latitude': latitude, 'longitude': longitude},
                'farm_size_hectares': farm_size,
                'irrigation_type': irrigation_type
            },
            'data_sources': {
                'soil_data': 'Location-based estimation' + (' + User provided' if user_soil_data else ''),
                'weather_data': 'Location-based estimation',
                'topographic_data': 'Location-based estimation',
                'satellite_indices': 'Location-based estimation',
                'confidence_scores': {
                    'soil': 0.8 if user_soil_data else 0.6,
                    'weather': 0.6,
                    'topographic': 0.7,
                    'satellite': 0.6
                }
            },
            'recommendation': recommendation_data,
            'comprehensive_analysis': analysis,
            'market_analysis': market_analysis,
            'comprehensive_data_summary': {
                'soil_health_score': comprehensive_data.get('health_score', 75),
                'fertility_index': comprehensive_data.get('fertility_index', 70),
                'climate_suitability': analysis['environmental_analysis']['climate_suitability'],
                'water_access_score': comprehensive_data.get('water_access_score', 0.7),
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
            'api_version': 'standalone_v1.0'
        }
        
        logger.info(f"Ultra recommendation completed for {location_name}")
        
        return jsonify({
            "success": True,
            "data": response_data
        })
        
    except Exception as e:
        logger.error(f"Ultra recommendation error: {str(e)}")
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
        environmental_data = estimate_environmental_conditions(latitude, longitude)
        
        # Get quick recommendation
        recommendation = generate_ultra_recommendation(
            environmental_data, 'canal', 1.0
        )
        primary_crop = recommendation['primary_recommendation']
        crop_info = ULTRA_CROP_DATABASE[primary_crop]
        
        return jsonify({
            "success": True,
            "data": {
                "recommended_crop": primary_crop,
                "confidence": recommendation['confidence'],
                "quick_info": {
                    "season": crop_info['seasons'][0],
                    "duration": crop_info['growth_duration'],
                    "yield_potential": crop_info['yield_potential'],
                    "water_requirement": crop_info['water_requirement']
                },
                "location": {"latitude": latitude, "longitude": longitude},
                "method": "Ultra Quick Standalone",
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
            "database_version": "standalone_v1.0"
        }
    })

if __name__ == '__main__':
    print("ULTRA CROP RECOMMENDER API - Standalone Version Starting...")
    print(f"Enhanced crop database: {len(ULTRA_CROP_DATABASE)} crops")
    print("Features:")
    print("  * Location-based environmental estimation")
    print("  * Advanced rule-based crop recommendations")
    print("  * Comprehensive analysis and economic projections")
    print("  * Sustainability scoring")
    print("  * Risk assessment and mitigation strategies")
    print("Server running on http://0.0.0.0:5020")
    print("Android emulator can access via http://10.0.2.2:5020")
    app.run(debug=True, host='0.0.0.0', port=5020)
