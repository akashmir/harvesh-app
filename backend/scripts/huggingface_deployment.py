"""
Hugging Face Spaces Deployment Script
Alternative deployment option using Hugging Face Spaces
"""

import os
import json
import shutil
from pathlib import Path

def create_huggingface_space():
    """Create the necessary files for Hugging Face Spaces deployment"""
    
    # Create app.py for Hugging Face Spaces
    app_content = '''
import gradio as gr
import pandas as pd
import numpy as np
import joblib
import json
from flask import Flask, request, jsonify
from flask_cors import CORS

# Load models
try:
    rf_model = joblib.load('models/random_forest_model.pkl')
    scaler = joblib.load('models/scaler.pkl')
    label_encoder = joblib.load('models/label_encoder.pkl')
    
    with open('models/model_info.json', 'r') as f:
        model_info = json.load(f)
    
    models_loaded = True
    print("Models loaded successfully!")
except Exception as e:
    print(f"Error loading models: {e}")
    models_loaded = False

def predict_crop(N, P, K, temperature, humidity, ph, rainfall, model_type="rf"):
    """Predict crop based on input features"""
    if not models_loaded:
        return "Error: Models not loaded", 0.0, []
    
    try:
        features = [N, P, K, temperature, humidity, ph, rainfall]
        
        if model_type == "rf":
            prediction = rf_model.predict([features])[0]
            probabilities = rf_model.predict_proba([features])[0]
            confidence = max(probabilities)
        else:
            # Neural network prediction
            features_scaled = scaler.transform([features])
            prediction_proba = nn_model.predict(features_scaled, verbose=0)[0]
            prediction = np.argmax(prediction_proba)
            confidence = max(prediction_proba)
        
        crop_name = label_encoder.inverse_transform([prediction])[0]
        
        # Get top 3 predictions
        if model_type == "rf":
            top_indices = np.argsort(probabilities)[-3:][::-1]
            top_crops = label_encoder.inverse_transform(top_indices)
            top_confidences = probabilities[top_indices]
        else:
            top_indices = np.argsort(prediction_proba)[-3:][::-1]
            top_crops = label_encoder.inverse_transform(top_indices)
            top_confidences = prediction_proba[top_indices]
        
        top_3 = [
            {"crop": crop, "confidence": float(conf)}
            for crop, conf in zip(top_crops, top_confidences)
        ]
        
        return crop_name, float(confidence), top_3
        
    except Exception as e:
        return f"Error: {str(e)}", 0.0, []

# Create Gradio interface
def create_interface():
    with gr.Blocks(title="Crop Recommendation System") as demo:
        gr.Markdown("# 🌱 Crop Recommendation System")
        gr.Markdown("Enter soil and environmental conditions to get crop recommendations.")
        
        with gr.Row():
            with gr.Column():
                N = gr.Slider(0, 200, value=90, label="Nitrogen (N) - kg/ha")
                P = gr.Slider(0, 200, value=42, label="Phosphorus (P) - kg/ha")
                K = gr.Slider(0, 200, value=43, label="Potassium (K) - kg/ha")
                temperature = gr.Slider(0, 50, value=20.88, label="Temperature (°C)")
                humidity = gr.Slider(0, 100, value=82.0, label="Humidity (%)")
                ph = gr.Slider(0, 14, value=6.5, label="Soil pH")
                rainfall = gr.Slider(0, 500, value=202.94, label="Rainfall (mm)")
                model_type = gr.Radio(["rf", "nn"], value="rf", label="Model Type")
                
                predict_btn = gr.Button("Get Recommendation", variant="primary")
            
            with gr.Column():
                recommended_crop = gr.Textbox(label="Recommended Crop", interactive=False)
                confidence = gr.Number(label="Confidence Score", interactive=False)
                top_predictions = gr.JSON(label="Top 3 Predictions", interactive=False)
        
        predict_btn.click(
            predict_crop,
            inputs=[N, P, K, temperature, humidity, ph, rainfall, model_type],
            outputs=[recommended_crop, confidence, top_predictions]
        )
        
        gr.Markdown("""
        ### How to use:
        1. Adjust the sliders to match your soil and environmental conditions
        2. Choose between Random Forest (rf) or Neural Network (nn) model
        3. Click "Get Recommendation" to see the suggested crop
        4. The system will show the top 3 crop recommendations with confidence scores
        """)
    
    return demo

# Create Flask API for programmatic access
app = Flask(__name__)
CORS(app)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'message': 'Crop Recommendation API is running',
        'models_loaded': models_loaded
    })

@app.route('/recommend', methods=['POST'])
def recommend_crop_api():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        required_fields = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
        missing_fields = [field for field in required_fields if field not in data]
        
        if missing_fields:
            return jsonify({
                'error': f'Missing required fields: {missing_fields}'
            }), 400
        
        crop, confidence, top_3 = predict_crop(
            data['N'], data['P'], data['K'],
            data['temperature'], data['humidity'], data['ph'], data['rainfall'],
            data.get('model_type', 'rf')
        )
        
        return jsonify({
            'recommended_crop': crop,
            'confidence': confidence,
            'top_3_predictions': top_3
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == "__main__":
    # Create Gradio interface
    demo = create_interface()
    
    # Launch both Gradio and Flask
    import threading
    
    def run_flask():
        app.run(host='0.0.0.0', port=7861, debug=False)
    
    def run_gradio():
        demo.launch(server_port=7860, server_name='0.0.0.0', share=True)
    
    # Start both servers
    flask_thread = threading.Thread(target=run_flask)
    flask_thread.daemon = True
    flask_thread.start()
    
    run_gradio()
'''
    
    # Create requirements.txt for Hugging Face
    requirements_content = '''gradio==3.50.2
flask==2.3.3
pandas==2.0.3
numpy==1.24.3
scikit-learn==1.3.0
tensorflow==2.13.0
joblib==1.3.2
flask-cors==4.0.0
'''
    
    # Create README.md for Hugging Face Space
    readme_content = '''---
title: Crop Recommendation System
emoji: 🌱
colorFrom: green
colorTo: yellow
sdk: docker
pinned: false
license: mit
app_port: 7860
---

# Crop Recommendation System

An AI-powered crop recommendation system that suggests the best crops to grow based on soil and environmental conditions.

## Features

- **Interactive Interface**: Easy-to-use web interface with sliders for input
- **Multiple Models**: Choose between Random Forest and Neural Network models
- **Top 3 Recommendations**: Get the best 3 crop suggestions with confidence scores
- **REST API**: Programmatic access via REST API endpoints
- **Real-time Predictions**: Instant crop recommendations

## How to Use

1. **Web Interface**: Use the sliders to input your soil and environmental conditions
2. **API Access**: Send POST requests to `/recommend` endpoint with JSON data
3. **Health Check**: Check service status at `/health` endpoint

## API Usage

### Health Check
```bash
curl https://your-space-url/health
```

### Get Crop Recommendation
```bash
curl -X POST https://your-space-url/recommend \\
  -H "Content-Type: application/json" \\
  -d '{
    "N": 90,
    "P": 42,
    "K": 43,
    "temperature": 20.88,
    "humidity": 82.00,
    "ph": 6.50,
    "rainfall": 202.94,
    "model_type": "rf"
  }'
```

## Input Parameters

- **N**: Nitrogen content in soil (kg/ha)
- **P**: Phosphorus content in soil (kg/ha)
- **K**: Potassium content in soil (kg/ha)
- **temperature**: Temperature in Celsius
- **humidity**: Humidity percentage
- **ph**: Soil pH level
- **rainfall**: Rainfall in mm

## Model Types

- **Random Forest (rf)**: Fast and interpretable
- **Neural Network (nn)**: More complex patterns, higher accuracy

## Technical Details

- Built with Python, Flask, and Gradio
- Uses scikit-learn and TensorFlow for machine learning
- Deployed on Hugging Face Spaces
- CORS enabled for cross-origin requests

## License

MIT License - feel free to use and modify!
'''
    
    # Create Dockerfile for Hugging Face
    dockerfile_content = '''FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    gcc \\
    g++ \\
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create models directory
RUN mkdir -p models

# Expose ports
EXPOSE 7860 7861

# Run the application
CMD ["python", "app.py"]
'''
    
    # Create the files
    try:
        with open('hf_app.py', 'w', encoding='utf-8') as f:
            f.write(app_content)
        
        with open('hf_requirements.txt', 'w', encoding='utf-8') as f:
            f.write(requirements_content)
        
        with open('hf_README.md', 'w', encoding='utf-8') as f:
            f.write(readme_content)
        
        with open('hf_Dockerfile', 'w', encoding='utf-8') as f:
            f.write(dockerfile_content)
    except Exception as e:
        print(f"Error creating files: {e}")
        return
    
    print("✅ Hugging Face deployment files created!")
    print("Files created:")
    print("- hf_app.py (main application)")
    print("- hf_requirements.txt (dependencies)")
    print("- hf_README.md (space description)")
    print("- hf_Dockerfile (container config)")
    print("\nTo deploy to Hugging Face:")
    print("1. Create a new Space at https://huggingface.co/new-space")
    print("2. Choose 'Docker' as SDK")
    print("3. Upload these files to your Space")
    print("4. Make sure your models/ directory is included")

if __name__ == "__main__":
    create_huggingface_space()
