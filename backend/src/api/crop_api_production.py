"""
Production Flask API for Crop Recommendation
Optimized for Google Cloud Run deployment
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import numpy as np
import json
import os
import logging
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
from src.api.train_model import CropRecommendationTrainer



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


# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Global variables for models
rf_model = None
nn_model = None
scaler = None
label_encoder = None
model_info = None

def load_models():
    """Load trained models and preprocessing objects"""
    global rf_model, nn_model, scaler, label_encoder, model_info
    
    try:
        # Load models
        rf_model = joblib.load('models/random_forest_model.pkl')
        scaler = joblib.load('models/scaler.pkl')
        label_encoder = joblib.load('models/label_encoder.pkl')
        
        # Load model info
        with open('models/model_info.json', 'r') as f:
            model_info = json.load(f)
            
        # Load neural network model
        try:
            from tensorflow.keras.models import load_model
            nn_model = load_model('models/neural_network_model.h5')
        except Exception as e:
            logger.warning(f"Neural network model not available: {e}")
            
        logger.info("Models loaded successfully!")
        return True
        
    except Exception as e:
        logger.error(f"Error loading models: {str(e)}")
        return False

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'message': 'Crop Recommendation API is running',
        'models_loaded': rf_model is not None,
        'version': '1.0.0'
    })

@app.route('/recommend', methods=['POST'])
def recommend_crop():
    """
    Recommend crop based on soil and environmental conditions
    
    Expected JSON payload:
    {
        "N": 90,
        "P": 42,
        "K": 43,
        "temperature": 20.88,
        "humidity": 82.00,
        "ph": 6.50,
        "rainfall": 202.94,
        "model_type": "rf"  // optional: "rf" or "nn"
    }
    """
    try:
        if rf_model is None:
            return jsonify({
                'error': 'Models not loaded. Please train models first.'
            }), 500
            
        # Get input data
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
            
        # Validate required fields
        required_fields = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
        missing_fields = [field for field in required_fields if field not in data]
        
        if missing_fields:
            return jsonify({
                'error': f'Missing required fields: {missing_fields}'
            }), 400
            
        # Extract features
        features = [data[field] for field in required_fields]
        
        # Validate feature values
        if not all(isinstance(f, (int, float)) for f in features):
            return jsonify({
                'error': 'All features must be numeric values'
            }), 400
            
        # Get model type (default to Random Forest)
        model_type = data.get('model_type', 'rf')
        
        if model_type not in ['rf', 'nn']:
            return jsonify({
                'error': 'model_type must be either "rf" or "nn"'
            }), 400
            
        # Make prediction
        if model_type == 'rf':
            # Random Forest prediction
            prediction = rf_model.predict([features])[0]
            probabilities = rf_model.predict_proba([features])[0]
            confidence = max(probabilities)
            
        else:  # Neural Network
            if nn_model is None:
                return jsonify({
                    'error': 'Neural Network model not available'
                }), 500
                
            features_scaled = scaler.transform([features])
            prediction_proba = nn_model.predict(features_scaled, verbose=0)[0]
            prediction = np.argmax(prediction_proba)
            confidence = max(prediction_proba)
            
        # Get crop name
        crop_name = label_encoder.inverse_transform([prediction])[0]
        
        # Get top 3 predictions with confidence scores
        if model_type == 'rf':
            top_indices = np.argsort(probabilities)[-3:][::-1]
            top_crops = label_encoder.inverse_transform(top_indices)
            top_confidences = probabilities[top_indices]
        else:
            top_indices = np.argsort(prediction_proba)[-3:][::-1]
            top_crops = label_encoder.inverse_transform(top_indices)
            top_confidences = prediction_proba[top_indices]
            
        # Prepare response
        response = {
            'recommended_crop': crop_name,
            'confidence': float(confidence),
            'model_type': model_type,
            'input_features': {
                'N': data['N'],
                'P': data['P'],
                'K': data['K'],
                'temperature': data['temperature'],
                'humidity': data['humidity'],
                'ph': data['ph'],
                'rainfall': data['rainfall']
            },
            'top_3_predictions': [
                {
                    'crop': crop,
                    'confidence': float(conf)
                }
                for crop, conf in zip(top_crops, top_confidences)
            ]
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        return jsonify({
            'error': f'Prediction failed: {str(e)}'
        }), 500

@app.route('/crops', methods=['GET'])
def get_available_crops():
    """Get list of all available crop types"""
    try:
        if model_info is None:
            return jsonify({'error': 'Model info not loaded'}), 500
            
        return jsonify({
            'crops': model_info['class_names'],
            'total_crops': model_info['num_classes']
        })
        
    except Exception as e:
        logger.error(f"Error getting crops: {str(e)}")
        return jsonify({
            'error': f'Failed to get crop list: {str(e)}'
        }), 500

@app.route('/features', methods=['GET'])
def get_feature_info():
    """Get information about required features"""
    try:
        if model_info is None:
            return jsonify({'error': 'Model info not loaded'}), 500
            
        feature_descriptions = {
            'N': 'Nitrogen content in soil (kg/ha)',
            'P': 'Phosphorus content in soil (kg/ha)',
            'K': 'Potassium content in soil (kg/ha)',
            'temperature': 'Temperature in Celsius',
            'humidity': 'Humidity percentage',
            'ph': 'Soil pH level',
            'rainfall': 'Rainfall in mm'
        }
        
        features = []
        for feature in model_info['feature_names']:
            features.append({
                'name': feature,
                'description': feature_descriptions.get(feature, 'No description available')
            })
            
        return jsonify({
            'features': features,
            'total_features': len(features)
        })
        
    except Exception as e:
        logger.error(f"Error getting features: {str(e)}")
        return jsonify({
            'error': f'Failed to get feature info: {str(e)}'
        }), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    logger.info("Starting Crop Recommendation API...")
    
    # Load models on startup
    if load_models():
        logger.info("API ready with trained models!")
    else:
        logger.warning("API started but models not loaded. Use /train endpoint to train models.")
    
    # Get port from environment variable (required for Cloud Run)
    port = int(os.environ.get('PORT', 8080))
    
    # Run the app
    app.run(host='0.0.0.0', port=port, debug=False)
