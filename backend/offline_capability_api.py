"""
Offline Capability API
Provides offline functionality for low-connectivity regions with data synchronization
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
import hashlib
import gzip
import base64

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database setup
DB_NAME = 'offline_capability.db'

# Offline data cache structure
OFFLINE_DATA_STRUCTURE = {
    'crop_recommendations': {
        'table': 'offline_crop_data',
        'fields': ['crop_name', 'soil_conditions', 'weather_conditions', 'recommendation', 'confidence'],
        'sync_priority': 'high'
    },
    'weather_data': {
        'table': 'offline_weather_data',
        'fields': ['location', 'date', 'temperature', 'humidity', 'rainfall', 'forecast'],
        'sync_priority': 'medium'
    },
    'market_prices': {
        'table': 'offline_market_data',
        'fields': ['crop_name', 'price', 'market', 'date', 'trend'],
        'sync_priority': 'medium'
    },
    'disease_database': {
        'table': 'offline_disease_data',
        'fields': ['crop_name', 'disease_name', 'symptoms', 'treatment', 'prevention'],
        'sync_priority': 'low'
    },
    'soil_data': {
        'table': 'offline_soil_data',
        'fields': ['location', 'ph', 'nitrogen', 'phosphorus', 'potassium', 'organic_matter'],
        'sync_priority': 'low'
    }
}

# Offline ML models cache
OFFLINE_MODELS = {
    'crop_recommendation': {
        'model_file': 'offline_crop_model.pkl',
        'scaler_file': 'offline_scaler.pkl',
        'label_encoder_file': 'offline_label_encoder.pkl',
        'last_updated': None,
        'version': '1.0'
    },
    'disease_detection': {
        'model_file': 'offline_disease_model.h5',
        'class_names_file': 'offline_disease_classes.json',
        'last_updated': None,
        'version': '1.0'
    }
}

def init_database():
    """Initialize the offline capability database"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    # Offline data tables
    for data_type, config in OFFLINE_DATA_STRUCTURE.items():
        table_name = config['table']
        fields = config['fields']
        
        # Create table with common fields
        create_sql = f'''
            CREATE TABLE IF NOT EXISTS {table_name} (
                id TEXT PRIMARY KEY,
                data_hash TEXT NOT NULL,
                sync_status TEXT DEFAULT 'pending',
                last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                sync_priority TEXT DEFAULT '{config['sync_priority']}',
                data_json TEXT NOT NULL
            )
        '''
        cursor.execute(create_sql)
    
    # Sync status table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS sync_status (
            id TEXT PRIMARY KEY,
            data_type TEXT NOT NULL,
            last_sync TIMESTAMP,
            sync_count INTEGER DEFAULT 0,
            last_error TEXT,
            sync_enabled BOOLEAN DEFAULT TRUE
        )
    ''')
    
    # Offline operations log
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS offline_operations (
            id TEXT PRIMARY KEY,
            operation_type TEXT NOT NULL,
            data_type TEXT NOT NULL,
            operation_data TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            synced_at TIMESTAMP
        )
    ''')
    
    # Local cache for frequently accessed data
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS local_cache (
            cache_key TEXT PRIMARY KEY,
            cache_data TEXT NOT NULL,
            expires_at TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    conn.commit()
    conn.close()

# Initialize database
init_database()

def generate_data_hash(data: Dict) -> str:
    """Generate hash for data integrity checking"""
    data_str = json.dumps(data, sort_keys=True)
    return hashlib.md5(data_str.encode()).hexdigest()

def store_offline_data(data_type: str, data: Dict, sync_priority: str = 'medium') -> str:
    """Store data for offline access"""
    try:
        if data_type not in OFFLINE_DATA_STRUCTURE:
            raise ValueError(f"Unknown data type: {data_type}")
        
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        # Generate unique ID and hash
        data_id = f"{data_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{hash(str(data)) % 10000}"
        data_hash = generate_data_hash(data)
        
        # Store data
        table_name = OFFLINE_DATA_STRUCTURE[data_type]['table']
        cursor.execute(f'''
            INSERT INTO {table_name} 
            (id, data_hash, sync_status, sync_priority, data_json)
            VALUES (?, ?, ?, ?, ?)
        ''', (data_id, data_hash, 'pending', sync_priority, json.dumps(data)))
        
        conn.commit()
        conn.close()
        
        return data_id
        
    except Exception as e:
        logger.error(f"Error storing offline data: {str(e)}")
        return None

def get_offline_data(data_type: str, filters: Dict = None) -> List[Dict]:
    """Retrieve offline data"""
    try:
        if data_type not in OFFLINE_DATA_STRUCTURE:
            return []
        
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        table_name = OFFLINE_DATA_STRUCTURE[data_type]['table']
        
        # Build query
        query = f"SELECT data_json FROM {table_name} WHERE 1=1"
        params = []
        
        if filters:
            for key, value in filters.items():
                query += f" AND JSON_EXTRACT(data_json, '$.{key}') = ?"
                params.append(value)
        
        query += " ORDER BY last_updated DESC"
        
        cursor.execute(query, params)
        rows = cursor.fetchall()
        
        data_list = []
        for row in rows:
            try:
                data_list.append(json.loads(row[0]))
            except json.JSONDecodeError:
                continue
        
        conn.close()
        return data_list
        
    except Exception as e:
        logger.error(f"Error retrieving offline data: {str(e)}")
        return []

def compress_data(data: Dict) -> str:
    """Compress data for efficient storage"""
    try:
        json_str = json.dumps(data)
        compressed = gzip.compress(json_str.encode())
        return base64.b64encode(compressed).decode()
    except Exception as e:
        logger.error(f"Data compression error: {str(e)}")
        return json.dumps(data)

def decompress_data(compressed_data: str) -> Dict:
    """Decompress data"""
    try:
        compressed_bytes = base64.b64decode(compressed_data)
        decompressed = gzip.decompress(compressed_bytes)
        return json.loads(decompressed.decode())
    except Exception as e:
        logger.error(f"Data decompression error: {str(e)}")
        return {}

def get_cached_data(cache_key: str) -> Optional[Dict]:
    """Get data from local cache"""
    try:
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT cache_data FROM local_cache 
            WHERE cache_key = ? AND expires_at > datetime('now')
        ''', (cache_key,))
        
        row = cursor.fetchone()
        conn.close()
        
        if row:
            return json.loads(row[0])
        return None
        
    except Exception as e:
        logger.error(f"Cache retrieval error: {str(e)}")
        return None

def set_cached_data(cache_key: str, data: Dict, expiry_hours: int = 24) -> bool:
    """Set data in local cache"""
    try:
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        expires_at = datetime.now() + timedelta(hours=expiry_hours)
        
        cursor.execute('''
            INSERT OR REPLACE INTO local_cache 
            (cache_key, cache_data, expires_at)
            VALUES (?, ?, ?)
        ''', (cache_key, json.dumps(data), expires_at))
        
        conn.commit()
        conn.close()
        return True
        
    except Exception as e:
        logger.error(f"Cache storage error: {str(e)}")
        return False

def generate_offline_crop_recommendation(soil_data: Dict, weather_data: Dict) -> Dict:
    """Generate crop recommendation using offline data"""
    try:
        # Use cached data if available
        cache_key = f"crop_rec_{hash(str(soil_data) + str(weather_data))}"
        cached_result = get_cached_data(cache_key)
        if cached_result:
            return cached_result
        
        # Simple offline recommendation logic
        ph = soil_data.get('ph', 6.5)
        nitrogen = soil_data.get('nitrogen', 100)
        temperature = weather_data.get('temperature', 25)
        rainfall = weather_data.get('rainfall', 500)
        
        # Basic crop selection logic
        if ph < 6.0:
            recommended_crops = ['Rice', 'Potato']
        elif ph > 8.0:
            recommended_crops = ['Wheat', 'Barley']
        else:
            recommended_crops = ['Rice', 'Wheat', 'Maize']
        
        # Adjust based on nitrogen
        if nitrogen < 80:
            recommended_crops = ['Soybean', 'Chickpea', 'Lentil']
        
        # Adjust based on temperature
        if temperature > 30:
            recommended_crops = ['Cotton', 'Sugarcane', 'Sorghum']
        elif temperature < 15:
            recommended_crops = ['Wheat', 'Barley', 'Oats']
        
        # Adjust based on rainfall
        if rainfall < 300:
            recommended_crops = ['Sorghum', 'Millet', 'Chickpea']
        elif rainfall > 1000:
            recommended_crops = ['Rice', 'Sugarcane']
        
        result = {
            'recommended_crops': recommended_crops[:3],  # Top 3
            'confidence': 0.75,  # Lower confidence for offline
            'method': 'offline_simple_logic',
            'timestamp': datetime.now().isoformat()
        }
        
        # Cache the result
        set_cached_data(cache_key, result, 6)  # Cache for 6 hours
        
        return result
        
    except Exception as e:
        logger.error(f"Offline crop recommendation error: {str(e)}")
        return {
            'recommended_crops': ['Rice'],  # Fallback
            'confidence': 0.5,
            'method': 'offline_fallback',
            'error': str(e)
        }

def generate_offline_disease_detection(image_features: Dict, crop_type: str) -> Dict:
    """Generate disease detection using offline data"""
    try:
        # Use cached data if available
        cache_key = f"disease_det_{hash(str(image_features) + crop_type)}"
        cached_result = get_cached_data(cache_key)
        if cached_result:
            return cached_result
        
        # Simple offline disease detection
        color_features = image_features.get('color_features', {})
        mean_g = color_features.get('mean_g', 0.5)
        
        # Basic disease detection logic
        if mean_g < 0.3:
            detected_disease = 'Nutrient Deficiency'
            confidence = 0.7
        elif mean_g > 0.8:
            detected_disease = 'Healthy Plant'
            confidence = 0.8
        else:
            detected_disease = 'Unknown Condition'
            confidence = 0.5
        
        result = {
            'disease': detected_disease,
            'confidence': confidence,
            'method': 'offline_simple_logic',
            'recommendations': [
                'Monitor plant health regularly',
                'Check soil nutrient levels',
                'Consult agricultural expert if symptoms persist'
            ],
            'timestamp': datetime.now().isoformat()
        }
        
        # Cache the result
        set_cached_data(cache_key, result, 12)  # Cache for 12 hours
        
        return result
        
    except Exception as e:
        logger.error(f"Offline disease detection error: {str(e)}")
        return {
            'disease': 'Detection Error',
            'confidence': 0.0,
            'method': 'offline_error',
            'error': str(e)
        }

def sync_offline_data() -> Dict:
    """Sync offline data with server when connection is available"""
    try:
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        sync_results = {}
        
        # Get pending sync operations
        for data_type, config in OFFLINE_DATA_STRUCTURE.items():
            table_name = config['table']
            
            cursor.execute(f'''
                SELECT id, data_json, sync_priority FROM {table_name} 
                WHERE sync_status = 'pending' 
                ORDER BY sync_priority DESC, last_updated ASC
            ''')
            
            pending_items = cursor.fetchall()
            
            sync_count = 0
            for item_id, data_json, priority in pending_items:
                try:
                    # Simulate sync operation (in real app, send to server)
                    data = json.loads(data_json)
                    
                    # Update sync status
                    cursor.execute(f'''
                        UPDATE {table_name} 
                        SET sync_status = 'synced' 
                        WHERE id = ?
                    ''', (item_id,))
                    
                    sync_count += 1
                    
                except Exception as e:
                    logger.error(f"Sync error for {item_id}: {str(e)}")
                    continue
            
            sync_results[data_type] = {
                'synced_items': sync_count,
                'status': 'success' if sync_count > 0 else 'no_pending'
            }
        
        conn.commit()
        conn.close()
        
        return {
            'sync_results': sync_results,
            'total_synced': sum(result['synced_items'] for result in sync_results.values()),
            'sync_timestamp': datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Data sync error: {str(e)}")
        return {
            'error': str(e),
            'sync_timestamp': datetime.now().isoformat()
        }

def get_offline_status() -> Dict:
    """Get offline capability status"""
    try:
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        status = {
            'offline_mode': True,
            'data_availability': {},
            'sync_status': {},
            'cache_status': {}
        }
        
        # Check data availability
        for data_type, config in OFFLINE_DATA_STRUCTURE.items():
            table_name = config['table']
            cursor.execute(f'SELECT COUNT(*) FROM {table_name}')
            count = cursor.fetchone()[0]
            status['data_availability'][data_type] = count > 0
        
        # Check sync status
        cursor.execute('''
            SELECT data_type, last_sync, sync_count, sync_enabled 
            FROM sync_status
        ''')
        
        for row in cursor.fetchall():
            status['sync_status'][row[0]] = {
                'last_sync': row[1],
                'sync_count': row[2],
                'enabled': bool(row[3])
            }
        
        # Check cache status
        cursor.execute('''
            SELECT COUNT(*) FROM local_cache 
            WHERE expires_at > datetime('now')
        ''')
        active_cache_count = cursor.fetchone()[0]
        
        status['cache_status'] = {
            'active_entries': active_cache_count,
            'cache_healthy': active_cache_count > 0
        }
        
        conn.close()
        return status
        
    except Exception as e:
        logger.error(f"Status check error: {str(e)}")
        return {
            'offline_mode': True,
            'error': str(e)
        }

# API Endpoints

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "success": True,
        "message": "Offline Capability API is running",
        "timestamp": datetime.now().isoformat(),
        "features": [
            "Offline data storage",
            "Local caching",
            "Data synchronization",
            "Offline crop recommendations",
            "Offline disease detection"
        ]
    })

@app.route('/offline/status', methods=['GET'])
def get_offline_status_endpoint():
    """Get offline capability status"""
    try:
        status = get_offline_status()
        return jsonify({
            "success": True,
            "data": status
        })
    except Exception as e:
        logger.error(f"Status endpoint error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/offline/crop-recommendation', methods=['POST'])
def offline_crop_recommendation():
    """Get crop recommendation in offline mode"""
    try:
        data = request.get_json()
        
        soil_data = data.get('soil_data', {})
        weather_data = data.get('weather_data', {})
        
        # Generate offline recommendation
        recommendation = generate_offline_crop_recommendation(soil_data, weather_data)
        
        # Store for later sync
        store_offline_data('crop_recommendations', {
            'soil_data': soil_data,
            'weather_data': weather_data,
            'recommendation': recommendation
        }, 'high')
        
        return jsonify({
            "success": True,
            "data": recommendation
        })
    
    except Exception as e:
        logger.error(f"Offline crop recommendation error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/offline/disease-detection', methods=['POST'])
def offline_disease_detection():
    """Detect diseases in offline mode"""
    try:
        data = request.get_json()
        
        image_features = data.get('image_features', {})
        crop_type = data.get('crop_type', 'Rice')
        
        # Generate offline disease detection
        detection = generate_offline_disease_detection(image_features, crop_type)
        
        # Store for later sync
        store_offline_data('disease_database', {
            'crop_type': crop_type,
            'image_features': image_features,
            'detection': detection
        }, 'medium')
        
        return jsonify({
            "success": True,
            "data": detection
        })
    
    except Exception as e:
        logger.error(f"Offline disease detection error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/offline/sync', methods=['POST'])
def sync_data():
    """Sync offline data with server"""
    try:
        sync_results = sync_offline_data()
        return jsonify({
            "success": True,
            "data": sync_results
        })
    
    except Exception as e:
        logger.error(f"Sync endpoint error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/offline/data/<data_type>', methods=['GET'])
def get_offline_data_endpoint(data_type):
    """Get offline data by type"""
    try:
        filters = {}
        for key, value in request.args.items():
            filters[key] = value
        
        data = get_offline_data(data_type, filters)
        
        return jsonify({
            "success": True,
            "data": {
                "data_type": data_type,
                "items": data,
                "count": len(data)
            }
        })
    
    except Exception as e:
        logger.error(f"Get offline data error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/offline/cache/clear', methods=['POST'])
def clear_cache():
    """Clear local cache"""
    try:
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        
        cursor.execute('DELETE FROM local_cache')
        conn.commit()
        conn.close()
        
        return jsonify({
            "success": True,
            "message": "Cache cleared successfully"
        })
    
    except Exception as e:
        logger.error(f"Cache clear error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/offline/export', methods=['GET'])
def export_offline_data():
    """Export offline data for backup"""
    try:
        data_type = request.args.get('data_type', 'all')
        
        export_data = {}
        
        if data_type == 'all':
            for dt in OFFLINE_DATA_STRUCTURE.keys():
                export_data[dt] = get_offline_data(dt)
        else:
            export_data[data_type] = get_offline_data(data_type)
        
        # Compress export data
        compressed_export = compress_data(export_data)
        
        return jsonify({
            "success": True,
            "data": {
                "export_data": compressed_export,
                "data_type": data_type,
                "export_timestamp": datetime.now().isoformat()
            }
        })
    
    except Exception as e:
        logger.error(f"Export error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

if __name__ == '__main__':
    print("📱 Offline Capability API Starting...")
    print(f"📊 Database: {DB_NAME}")
    print(f"🗄️ Data types: {len(OFFLINE_DATA_STRUCTURE)}")
    print(f"🤖 Offline models: {len(OFFLINE_MODELS)}")
    print("🚀 Server running on http://0.0.0.0:5011")
    print("📱 Android emulator can access via http://10.0.2.2:5011")
    app.run(debug=True, host='0.0.0.0', port=5011)
