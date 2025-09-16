"""
Crop Calendar/Scheduler API
Provides planting and harvesting schedules for different crops
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import calendar
import gzip
import io

app = Flask(__name__)
CORS(app)

# Crop calendar data with planting and harvesting schedules
CROP_CALENDAR_DATA = {
    "rice": {
        "name": "Rice",
        "planting_months": [4, 5, 6, 7],  # April to July
        "harvesting_months": [8, 9, 10, 11],  # August to November
        "growing_days": 120,
        "seasons": ["Kharif"],
        "description": "Rice is a staple crop grown in wet conditions"
    },
    "maize": {
        "name": "Maize",
        "planting_months": [3, 4, 5, 6],  # March to June
        "harvesting_months": [7, 8, 9, 10],  # July to October
        "growing_days": 90,
        "seasons": ["Kharif", "Rabi"],
        "description": "Maize is a versatile crop grown in various conditions"
    },
    "wheat": {
        "name": "Wheat",
        "planting_months": [10, 11, 12],  # October to December
        "harvesting_months": [3, 4, 5],  # March to May
        "growing_days": 150,
        "seasons": ["Rabi"],
        "description": "Wheat is a winter crop requiring cool temperatures"
    },
    "cotton": {
        "name": "Cotton",
        "planting_months": [4, 5, 6],  # April to June
        "harvesting_months": [9, 10, 11, 12],  # September to December
        "growing_days": 180,
        "seasons": ["Kharif"],
        "description": "Cotton requires warm temperatures and adequate moisture"
    },
    "sugarcane": {
        "name": "Sugarcane",
        "planting_months": [2, 3, 4, 5, 6, 7, 8, 9, 10],  # February to October
        "harvesting_months": [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],  # Year-round
        "growing_days": 365,
        "seasons": ["Kharif", "Rabi", "Zaid"],
        "description": "Sugarcane is a perennial crop with year-round harvesting"
    },
    "mango": {
        "name": "Mango",
        "planting_months": [6, 7, 8],  # June to August
        "harvesting_months": [3, 4, 5, 6],  # March to June
        "growing_days": 300,
        "seasons": ["Kharif"],
        "description": "Mango is a tropical fruit tree"
    },
    "banana": {
        "name": "Banana",
        "planting_months": [6, 7, 8, 9],  # June to September
        "harvesting_months": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],  # Year-round
        "growing_days": 270,
        "seasons": ["Kharif", "Rabi", "Zaid"],
        "description": "Banana can be planted and harvested year-round"
    },
    "coconut": {
        "name": "Coconut",
        "planting_months": [5, 6, 7, 8],  # May to August
        "harvesting_months": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],  # Year-round
        "growing_days": 365,
        "seasons": ["Kharif", "Rabi", "Zaid"],
        "description": "Coconut is a perennial crop with year-round harvesting"
    },
    "orange": {
        "name": "Orange",
        "planting_months": [6, 7, 8],  # June to August
        "harvesting_months": [11, 12, 1, 2, 3],  # November to March
        "growing_days": 240,
        "seasons": ["Kharif"],
        "description": "Orange is a citrus fruit tree"
    },
    "apple": {
        "name": "Apple",
        "planting_months": [1, 2, 3, 11, 12],  # January to March, November to December
        "harvesting_months": [7, 8, 9, 10],  # July to October
        "growing_days": 200,
        "seasons": ["Rabi"],
        "description": "Apple requires cool climate and winter chill"
    },
    "grapes": {
        "name": "Grapes",
        "planting_months": [1, 2, 3, 11, 12],  # January to March, November to December
        "harvesting_months": [4, 5, 6, 7, 8, 9],  # April to September
        "growing_days": 180,
        "seasons": ["Rabi"],
        "description": "Grapes are grown in temperate regions"
    },
    "watermelon": {
        "name": "Watermelon",
        "planting_months": [2, 3, 4, 5, 6],  # February to June
        "harvesting_months": [5, 6, 7, 8, 9],  # May to September
        "growing_days": 90,
        "seasons": ["Zaid", "Kharif"],
        "description": "Watermelon is a summer crop requiring warm temperatures"
    },
    "muskmelon": {
        "name": "Muskmelon",
        "planting_months": [2, 3, 4, 5, 6],  # February to June
        "harvesting_months": [5, 6, 7, 8, 9],  # May to September
        "growing_days": 85,
        "seasons": ["Zaid", "Kharif"],
        "description": "Muskmelon is a summer crop similar to watermelon"
    },
    "papaya": {
        "name": "Papaya",
        "planting_months": [6, 7, 8, 9],  # June to September
        "harvesting_months": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],  # Year-round
        "growing_days": 300,
        "seasons": ["Kharif", "Rabi", "Zaid"],
        "description": "Papaya is a tropical fruit tree"
    },
    "pomegranate": {
        "name": "Pomegranate",
        "planting_months": [6, 7, 8],  # June to August
        "harvesting_months": [9, 10, 11, 12, 1, 2],  # September to February
        "growing_days": 180,
        "seasons": ["Kharif"],
        "description": "Pomegranate is a drought-resistant fruit tree"
    },
    "lentil": {
        "name": "Lentil",
        "planting_months": [10, 11, 12],  # October to December
        "harvesting_months": [2, 3, 4],  # February to April
        "growing_days": 120,
        "seasons": ["Rabi"],
        "description": "Lentil is a winter legume crop"
    },
    "chickpea": {
        "name": "Chickpea",
        "planting_months": [10, 11, 12],  # October to December
        "harvesting_months": [2, 3, 4],  # February to April
        "growing_days": 130,
        "seasons": ["Rabi"],
        "description": "Chickpea is a winter legume crop"
    },
    "blackgram": {
        "name": "Blackgram",
        "planting_months": [6, 7, 8],  # June to August
        "harvesting_months": [9, 10, 11],  # September to November
        "growing_days": 90,
        "seasons": ["Kharif"],
        "description": "Blackgram is a summer legume crop"
    },
    "mungbean": {
        "name": "Mungbean",
        "planting_months": [3, 4, 5, 6, 7],  # March to July
        "harvesting_months": [6, 7, 8, 9, 10],  # June to October
        "growing_days": 70,
        "seasons": ["Zaid", "Kharif"],
        "description": "Mungbean is a short-duration legume crop"
    },
    "pigeonpeas": {
        "name": "Pigeonpeas",
        "planting_months": [6, 7, 8],  # June to August
        "harvesting_months": [11, 12, 1, 2],  # November to February
        "growing_days": 150,
        "seasons": ["Kharif"],
        "description": "Pigeonpeas is a long-duration legume crop"
    },
    "kidneybeans": {
        "name": "Kidneybeans",
        "planting_months": [6, 7, 8],  # June to August
        "harvesting_months": [9, 10, 11],  # September to November
        "growing_days": 90,
        "seasons": ["Kharif"],
        "description": "Kidneybeans is a summer legume crop"
    },
    "mothbeans": {
        "name": "Mothbeans",
        "planting_months": [6, 7, 8],  # June to August
        "harvesting_months": [9, 10, 11],  # September to November
        "growing_days": 80,
        "seasons": ["Kharif"],
        "description": "Mothbeans is a short-duration legume crop"
    },
    "jute": {
        "name": "Jute",
        "planting_months": [3, 4, 5],  # March to May
        "harvesting_months": [6, 7, 8],  # June to August
        "growing_days": 120,
        "seasons": ["Zaid"],
        "description": "Jute is a fiber crop grown in warm, humid conditions"
    },
    "coffee": {
        "name": "Coffee",
        "planting_months": [6, 7, 8],  # June to August
        "harvesting_months": [10, 11, 12, 1, 2, 3],  # October to March
        "growing_days": 365,
        "seasons": ["Kharif"],
        "description": "Coffee is a perennial crop grown in tropical regions"
    }
}

# Season information
SEASONS = {
    "Kharif": {
        "name": "Kharif",
        "months": [6, 7, 8, 9, 10, 11],  # June to November
        "description": "Monsoon season crops"
    },
    "Rabi": {
        "name": "Rabi",
        "months": [10, 11, 12, 1, 2, 3],  # October to March
        "description": "Winter season crops"
    },
    "Zaid": {
        "name": "Zaid",
        "months": [3, 4, 5, 6],  # March to June
        "description": "Summer season crops"
    }
}

def get_current_month():
    """Get current month (1-12)"""
    return datetime.now().month

def get_month_name(month_num):
    """Get month name from number"""
    return calendar.month_name[month_num]

def is_planting_season(crop_name, month=None):
    """Check if it's planting season for a crop"""
    if month is None:
        month = get_current_month()
    
    crop_data = CROP_CALENDAR_DATA.get(crop_name.lower())
    if not crop_data:
        return False
    
    return month in crop_data["planting_months"]

def is_harvesting_season(crop_name, month=None):
    """Check if it's harvesting season for a crop"""
    if month is None:
        month = get_current_month()
    
    crop_data = CROP_CALENDAR_DATA.get(crop_name.lower())
    if not crop_data:
        return False
    
    return month in crop_data["harvesting_months"]

def get_planting_schedule(crop_name):
    """Get planting schedule for a crop"""
    crop_data = CROP_CALENDAR_DATA.get(crop_name.lower())
    if not crop_data:
        return None
    
    return {
        "crop": crop_data["name"],
        "planting_months": [get_month_name(m) for m in crop_data["planting_months"]],
        "planting_months_nums": crop_data["planting_months"],
        "harvesting_months": [get_month_name(m) for m in crop_data["harvesting_months"]],
        "harvesting_months_nums": crop_data["harvesting_months"],
        "growing_days": crop_data["growing_days"],
        "seasons": crop_data["seasons"],
        "description": crop_data["description"],
        "is_planting_now": is_planting_season(crop_name),
        "is_harvesting_now": is_harvesting_season(crop_name)
    }

def get_crops_by_season(season):
    """Get crops suitable for a specific season"""
    season_data = SEASONS.get(season)
    if not season_data:
        return []
    
    suitable_crops = []
    for crop_name, crop_data in CROP_CALENDAR_DATA.items():
        if season in crop_data["seasons"]:
            suitable_crops.append({
                "crop": crop_data["name"],
                "crop_key": crop_name,
                "planting_months": [get_month_name(m) for m in crop_data["planting_months"]],
                "harvesting_months": [get_month_name(m) for m in crop_data["harvesting_months"]],
                "growing_days": crop_data["growing_days"]
            })
    
    return suitable_crops

def get_monthly_calendar(month=None):
    """Get calendar for a specific month"""
    if month is None:
        month = get_current_month()
    
    month_name = get_month_name(month)
    
    planting_crops = []
    harvesting_crops = []
    
    for crop_name, crop_data in CROP_CALENDAR_DATA.items():
        if month in crop_data["planting_months"]:
            planting_crops.append({
                "crop": crop_data["name"],
                "crop_key": crop_name,
                "growing_days": crop_data["growing_days"],
                "seasons": crop_data["seasons"]
            })
        
        if month in crop_data["harvesting_months"]:
            harvesting_crops.append({
                "crop": crop_data["name"],
                "crop_key": crop_name,
                "growing_days": crop_data["growing_days"],
                "seasons": crop_data["seasons"]
            })
    
    return {
        "month": month,
        "month_name": month_name,
        "planting_crops": planting_crops,
        "harvesting_crops": harvesting_crops,
        "total_planting": len(planting_crops),
        "total_harvesting": len(harvesting_crops)
    }

def get_yearly_calendar():
    """Get complete yearly calendar"""
    yearly_calendar = []
    
    for month in range(1, 13):
        monthly_data = get_monthly_calendar(month)
        yearly_calendar.append(monthly_data)
    
    return yearly_calendar

# API Routes

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "Crop Calendar API",
        "version": "1.0.0",
        "total_crops": len(CROP_CALENDAR_DATA),
        "total_seasons": len(SEASONS)
    })

@app.route('/calendar/crop/<crop_name>', methods=['GET'])
def get_crop_schedule(crop_name):
    """Get planting and harvesting schedule for a specific crop"""
    try:
        schedule = get_planting_schedule(crop_name)
        if not schedule:
            return jsonify({
                "error": "Crop not found",
                "message": f"No calendar data available for {crop_name}"
            }), 404
        
        return jsonify({
            "success": True,
            "data": schedule
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/calendar/month/<int:month>', methods=['GET'])
def get_monthly_schedule(month):
    """Get crops for planting and harvesting in a specific month"""
    try:
        if month < 1 or month > 12:
            return jsonify({
                "error": "Invalid month",
                "message": "Month must be between 1 and 12"
            }), 400
        
        monthly_data = get_monthly_calendar(month)
        
        return jsonify({
            "success": True,
            "data": monthly_data
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/calendar/season/<season>', methods=['GET'])
def get_seasonal_crops(season):
    """Get crops suitable for a specific season"""
    try:
        crops = get_crops_by_season(season)
        
        if not crops:
            return jsonify({
                "error": "Season not found",
                "message": f"No crops available for season {season}",
                "available_seasons": list(SEASONS.keys())
            }), 404
        
        return jsonify({
            "success": True,
            "data": {
                "season": season,
                "crops": crops,
                "total_crops": len(crops)
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/calendar/yearly', methods=['GET'])
def get_yearly_schedule():
    """Get complete yearly calendar"""
    try:
        yearly_data = get_yearly_calendar()
        
        response_data = {
            "success": True,
            "data": {
                "yearly_calendar": yearly_data,
                "seasons": SEASONS,
                "total_months": 12
            }
        }
        
        response = jsonify(response_data)
        response.headers['Content-Type'] = 'application/json; charset=utf-8'
        response.headers['Cache-Control'] = 'public, max-age=300'  # Cache for 5 minutes
        return response
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/calendar/current', methods=['GET'])
def get_current_schedule():
    """Get current month's planting and harvesting schedule"""
    try:
        current_data = get_monthly_calendar()
        
        response = jsonify({
            "success": True,
            "data": current_data
        })
        response.headers['Cache-Control'] = 'public, max-age=60'  # Cache for 1 minute
        return response
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/calendar/yearly/summary', methods=['GET'])
def get_yearly_summary():
    """Get simplified yearly calendar summary"""
    try:
        yearly_data = get_yearly_calendar()
        
        # Create a simplified version with just counts
        summary_data = []
        for month_data in yearly_data:
            summary_data.append({
                "month": month_data['month'],
                "month_name": month_data['month_name'],
                "planting_count": month_data['total_planting'],
                "harvesting_count": month_data['total_harvesting'],
                "planting_crops": [crop['crop'] for crop in month_data['planting_crops'][:3]],  # Top 3 only
                "harvesting_crops": [crop['crop'] for crop in month_data['harvesting_crops'][:3]]  # Top 3 only
            })
        
        response = jsonify({
            "success": True,
            "data": {
                "yearly_summary": summary_data,
                "seasons": SEASONS,
                "total_months": 12
            }
        })
        response.headers['Cache-Control'] = 'public, max-age=300'
        return response
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/calendar/crops', methods=['GET'])
def get_all_crops():
    """Get list of all available crops with basic info"""
    try:
        crops = []
        for crop_name, crop_data in CROP_CALENDAR_DATA.items():
            crops.append({
                "crop": crop_data["name"],
                "crop_key": crop_name,
                "seasons": crop_data["seasons"],
                "growing_days": crop_data["growing_days"],
                "is_planting_now": is_planting_season(crop_name),
                "is_harvesting_now": is_harvesting_season(crop_name)
            })
        
        return jsonify({
            "success": True,
            "data": {
                "crops": crops,
                "total_crops": len(crops)
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/calendar/seasons', methods=['GET'])
def get_seasons():
    """Get information about all seasons"""
    try:
        return jsonify({
            "success": True,
            "data": {
                "seasons": SEASONS,
                "total_seasons": len(SEASONS)
            }
        })
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

if __name__ == '__main__':
    print("🌱 Crop Calendar API Starting...")
    print(f"📅 Available crops: {len(CROP_CALENDAR_DATA)}")
    print(f"🌾 Available seasons: {len(SEASONS)}")
    print("🚀 Server running on http://0.0.0.0:5001")
    print("📱 Android emulator can access via http://10.0.2.2:5001")
    app.run(debug=True, host='0.0.0.0', port=5001)
