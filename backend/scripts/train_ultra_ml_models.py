"""
Train Enhanced ML Models for Ultra Crop Recommender
Creates ensemble models (Random Forest + Neural Network + XGBoost) with extended features
"""

import numpy as np
import pandas as pd
import pickle
import json
import os
from sklearn.ensemble import RandomForestClassifier, VotingClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import xgboost as xgb
import joblib

# Enhanced feature set for Ultra Crop Recommender
ENHANCED_FEATURES = [
    'nitrogen', 'phosphorus', 'potassium', 'temperature', 'humidity', 
    'ph', 'rainfall', 'soil_moisture', 'organic_carbon', 'clay_content',
    'sand_content', 'elevation', 'slope', 'ndvi', 'evi', 'water_access_score'
]

CROP_LABELS = ['Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane', 'Soybean']

def generate_enhanced_training_data(n_samples=5000):
    """Generate enhanced synthetic training data with realistic patterns"""
    np.random.seed(42)
    data = []
    labels = []
    
    # Define crop-specific parameter ranges
    crop_params = {
        'Rice': {
            'nitrogen': (80, 150), 'phosphorus': (20, 40), 'potassium': (150, 250),
            'temperature': (20, 35), 'humidity': (60, 90), 'ph': (5.5, 7.5),
            'rainfall': (1000, 2000), 'soil_moisture': (60, 90), 'organic_carbon': (1.0, 2.5),
            'clay_content': (30, 60), 'sand_content': (20, 40), 'elevation': (0, 500),
            'slope': (0, 8), 'ndvi': (0.4, 0.8), 'evi': (0.3, 0.7), 'water_access_score': (0.7, 1.0)
        },
        'Wheat': {
            'nitrogen': (60, 120), 'phosphorus': (15, 35), 'potassium': (100, 200),
            'temperature': (15, 25), 'humidity': (40, 70), 'ph': (6.0, 7.5),
            'rainfall': (500, 1000), 'soil_moisture': (40, 70), 'organic_carbon': (0.8, 2.0),
            'clay_content': (25, 50), 'sand_content': (30, 50), 'elevation': (100, 800),
            'slope': (0, 12), 'ndvi': (0.3, 0.7), 'evi': (0.2, 0.6), 'water_access_score': (0.5, 0.9)
        },
        'Maize': {
            'nitrogen': (100, 180), 'phosphorus': (25, 45), 'potassium': (120, 280),
            'temperature': (18, 27), 'humidity': (50, 80), 'ph': (6.0, 7.0),
            'rainfall': (600, 1000), 'soil_moisture': (45, 75), 'organic_carbon': (1.0, 2.2),
            'clay_content': (20, 45), 'sand_content': (35, 60), 'elevation': (0, 600),
            'slope': (0, 10), 'ndvi': (0.4, 0.8), 'evi': (0.3, 0.7), 'water_access_score': (0.6, 0.9)
        },
        'Cotton': {
            'nitrogen': (80, 140), 'phosphorus': (20, 40), 'potassium': (150, 300),
            'temperature': (21, 30), 'humidity': (50, 75), 'ph': (6.0, 8.0),
            'rainfall': (500, 1000), 'soil_moisture': (40, 70), 'organic_carbon': (0.8, 1.8),
            'clay_content': (25, 55), 'sand_content': (25, 50), 'elevation': (100, 700),
            'slope': (0, 8), 'ndvi': (0.3, 0.7), 'evi': (0.2, 0.6), 'water_access_score': (0.6, 0.9)
        },
        'Sugarcane': {
            'nitrogen': (120, 200), 'phosphorus': (30, 50), 'potassium': (200, 400),
            'temperature': (26, 32), 'humidity': (65, 85), 'ph': (6.0, 7.5),
            'rainfall': (1000, 1500), 'soil_moisture': (70, 95), 'organic_carbon': (1.5, 3.0),
            'clay_content': (35, 65), 'sand_content': (15, 35), 'elevation': (0, 400),
            'slope': (0, 6), 'ndvi': (0.5, 0.9), 'evi': (0.4, 0.8), 'water_access_score': (0.8, 1.0)
        },
        'Soybean': {
            'nitrogen': (40, 80), 'phosphorus': (20, 40), 'potassium': (120, 220),
            'temperature': (20, 30), 'humidity': (50, 75), 'ph': (6.0, 7.0),
            'rainfall': (600, 1000), 'soil_moisture': (45, 75), 'organic_carbon': (1.2, 2.5),
            'clay_content': (20, 45), 'sand_content': (30, 55), 'elevation': (100, 600),
            'slope': (0, 10), 'ndvi': (0.4, 0.8), 'evi': (0.3, 0.7), 'water_access_score': (0.6, 0.9)
        }
    }
    
    samples_per_crop = n_samples // len(CROP_LABELS)
    
    for crop in CROP_LABELS:
        params = crop_params[crop]
        
        for _ in range(samples_per_crop):
            sample = []
            
            for feature in ENHANCED_FEATURES:
                min_val, max_val = params[feature]
                # Add some noise and correlation
                value = np.random.uniform(min_val, max_val)
                
                # Add realistic correlations
                if feature == 'soil_moisture' and 'rainfall' in [f for f in ENHANCED_FEATURES[:len(sample)]]:
                    rainfall_idx = ENHANCED_FEATURES.index('rainfall')
                    if len(sample) > rainfall_idx:
                        rainfall_val = sample[rainfall_idx]
                        # Soil moisture correlated with rainfall
                        value = min(max_val, value + (rainfall_val - 750) * 0.01)
                
                if feature == 'ndvi' and 'organic_carbon' in [f for f in ENHANCED_FEATURES[:len(sample)]]:
                    oc_idx = ENHANCED_FEATURES.index('organic_carbon')
                    if len(sample) > oc_idx:
                        oc_val = sample[oc_idx]
                        # NDVI correlated with organic carbon
                        value = min(max_val, value + (oc_val - 1.5) * 0.1)
                
                sample.append(round(value, 3))
            
            data.append(sample)
            labels.append(crop)
    
    return np.array(data), np.array(labels)

def train_enhanced_models():
    """Train ensemble ML models for Ultra Crop Recommender"""
    print("Starting Enhanced ML Model Training...")
    
    # Generate training data
    print("Generating enhanced training data...")
    X, y = generate_enhanced_training_data(n_samples=10000)
    
    # Create DataFrame for better handling
    df = pd.DataFrame(X, columns=ENHANCED_FEATURES)
    df['crop'] = y
    
    print(f"Generated {len(df)} samples with {len(ENHANCED_FEATURES)} features")
    print(f"Crop distribution:")
    print(df['crop'].value_counts())
    
    # Prepare features and labels
    X = df[ENHANCED_FEATURES].values
    y = df['crop'].values
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Scale features
    print("Scaling features...")
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Encode labels
    label_encoder = LabelEncoder()
    y_train_encoded = label_encoder.fit_transform(y_train)
    y_test_encoded = label_encoder.transform(y_test)
    
    # Train Random Forest
    print("Training Random Forest...")
    rf_model = RandomForestClassifier(
        n_estimators=200,
        max_depth=15,
        min_samples_split=5,
        min_samples_leaf=2,
        random_state=42,
        n_jobs=-1
    )
    rf_model.fit(X_train_scaled, y_train_encoded)
    rf_score = rf_model.score(X_test_scaled, y_test_encoded)
    print(f"Random Forest Accuracy: {rf_score:.4f}")
    
    # Train Neural Network
    print("Training Neural Network...")
    nn_model = MLPClassifier(
        hidden_layer_sizes=(200, 100, 50),
        max_iter=1000,
        alpha=0.001,
        learning_rate='adaptive',
        random_state=42
    )
    nn_model.fit(X_train_scaled, y_train_encoded)
    nn_score = nn_model.score(X_test_scaled, y_test_encoded)
    print(f"Neural Network Accuracy: {nn_score:.4f}")
    
    # Train XGBoost
    print("Training XGBoost...")
    xgb_model = xgb.XGBClassifier(
        n_estimators=200,
        max_depth=8,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.8,
        random_state=42,
        n_jobs=-1
    )
    xgb_model.fit(X_train_scaled, y_train_encoded)
    xgb_score = xgb_model.score(X_test_scaled, y_test_encoded)
    print(f"XGBoost Accuracy: {xgb_score:.4f}")
    
    # Create Ensemble Model
    print("Creating Ensemble Model...")
    ensemble_model = VotingClassifier(
        estimators=[
            ('rf', rf_model),
            ('nn', nn_model),
            ('xgb', xgb_model)
        ],
        voting='soft'
    )
    ensemble_model.fit(X_train_scaled, y_train_encoded)
    ensemble_score = ensemble_model.score(X_test_scaled, y_test_encoded)
    print(f"Ensemble Model Accuracy: {ensemble_score:.4f}")
    
    # Detailed evaluation
    print("\nDetailed Model Evaluation:")
    y_pred_ensemble = ensemble_model.predict(X_test_scaled)
    print("\nClassification Report:")
    print(classification_report(y_test_encoded, y_pred_ensemble, 
                              target_names=label_encoder.classes_))
    
    # Feature importance (from Random Forest)
    print("\nFeature Importance (Random Forest):")
    feature_importance = pd.DataFrame({
        'feature': ENHANCED_FEATURES,
        'importance': rf_model.feature_importances_
    }).sort_values('importance', ascending=False)
    
    print(feature_importance.head(10))
    
    # Save models
    models_dir = os.path.join(os.path.dirname(__file__), '..', 'models')
    os.makedirs(models_dir, exist_ok=True)
    
    print(f"\nSaving models to {models_dir}...")
    
    # Save individual models
    with open(os.path.join(models_dir, 'random_forest_model.pkl'), 'wb') as f:
        pickle.dump(rf_model, f)
    
    with open(os.path.join(models_dir, 'neural_network_model.pkl'), 'wb') as f:
        pickle.dump(nn_model, f)
    
    # Save XGBoost model
    xgb_model.save_model(os.path.join(models_dir, 'xgboost_model.json'))
    
    # Save ensemble model
    with open(os.path.join(models_dir, 'ensemble_model.pkl'), 'wb') as f:
        pickle.dump(ensemble_model, f)
    
    # Save scaler and label encoder
    with open(os.path.join(models_dir, 'scaler.pkl'), 'wb') as f:
        pickle.dump(scaler, f)
    
    with open(os.path.join(models_dir, 'label_encoder.pkl'), 'wb') as f:
        pickle.dump(label_encoder, f)
    
    # Save model metadata
    model_info = {
        'version': '2.0',
        'training_date': pd.Timestamp.now().isoformat(),
        'features': ENHANCED_FEATURES,
        'crops': CROP_LABELS,
        'model_scores': {
            'random_forest': float(rf_score),
            'neural_network': float(nn_score),
            'xgboost': float(xgb_score),
            'ensemble': float(ensemble_score)
        },
        'training_samples': len(X_train),
        'test_samples': len(X_test),
        'feature_importance': feature_importance.to_dict('records')
    }
    
    with open(os.path.join(models_dir, 'model_info.json'), 'w') as f:
        json.dump(model_info, f, indent=2)
    
    print("All models saved successfully!")
    print(f"Best performing model: {'Ensemble' if ensemble_score == max(rf_score, nn_score, xgb_score, ensemble_score) else 'Individual'}")
    print(f"Final Ensemble Accuracy: {ensemble_score:.4f}")
    
    return ensemble_model, scaler, label_encoder

def test_model_prediction():
    """Test the trained models with sample predictions"""
    print("\nTesting Model Predictions...")
    
    models_dir = os.path.join(os.path.dirname(__file__), '..', 'models')
    
    # Load models
    with open(os.path.join(models_dir, 'ensemble_model.pkl'), 'rb') as f:
        ensemble_model = pickle.load(f)
    
    with open(os.path.join(models_dir, 'scaler.pkl'), 'rb') as f:
        scaler = pickle.load(f)
    
    with open(os.path.join(models_dir, 'label_encoder.pkl'), 'rb') as f:
        label_encoder = pickle.load(f)
    
    # Test samples
    test_samples = [
        {
            'name': 'Rice-suitable conditions',
            'features': [120, 30, 200, 28, 75, 6.5, 1200, 80, 1.8, 45, 30, 100, 3, 0.7, 0.6, 0.9]
        },
        {
            'name': 'Wheat-suitable conditions', 
            'features': [90, 25, 150, 20, 55, 7.0, 700, 55, 1.2, 35, 40, 300, 5, 0.5, 0.4, 0.7]
        },
        {
            'name': 'Maize-suitable conditions',
            'features': [140, 35, 200, 24, 65, 6.8, 800, 60, 1.5, 30, 45, 200, 4, 0.6, 0.5, 0.8]
        }
    ]
    
    for sample in test_samples:
        features = np.array([sample['features']])
        features_scaled = scaler.transform(features)
        
        # Get prediction
        prediction = ensemble_model.predict(features_scaled)[0]
        probabilities = ensemble_model.predict_proba(features_scaled)[0]
        
        crop_name = label_encoder.inverse_transform([prediction])[0]
        confidence = probabilities.max()
        
        print(f"\n{sample['name']}:")
        print(f"   Predicted Crop: {crop_name}")
        print(f"   Confidence: {confidence:.3f}")
        
        # Show top 3 predictions
        top_indices = np.argsort(probabilities)[-3:][::-1]
        print("   Top 3 Predictions:")
        for i, idx in enumerate(top_indices, 1):
            crop = label_encoder.inverse_transform([idx])[0]
            prob = probabilities[idx]
            print(f"      {i}. {crop}: {prob:.3f}")

if __name__ == "__main__":
    # Train models
    ensemble_model, scaler, label_encoder = train_enhanced_models()
    
    # Test predictions
    test_model_prediction()
    
    print("\nUltra Crop Recommender ML Training Complete!")
    print("Models are ready for integration with the API.")
