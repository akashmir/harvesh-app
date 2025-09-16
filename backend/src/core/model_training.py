"""
Crop Recommendation Model Training Script
This script trains both RandomForest and Neural Network models for crop recommendation.
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
from tensorflow.keras.utils import to_categorical
import joblib
import json
import os

class CropRecommendationTrainer:
    def __init__(self, data_path='Crop_recommendation.csv'):
        self.data_path = data_path
        self.df = None
        self.X = None
        self.y = None
        self.X_train = None
        self.X_test = None
        self.y_train = None
        self.y_test = None
        self.scaler = StandardScaler()
        self.label_encoder = LabelEncoder()
        self.rf_model = None
        self.nn_model = None
        self.feature_names = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
        
    def load_and_preprocess_data(self):
        """Load and preprocess the dataset"""
        print("Loading dataset...")
        self.df = pd.read_csv(self.data_path)
        
        print(f"Dataset shape: {self.df.shape}")
        print(f"Features: {self.feature_names}")
        print(f"Target classes: {self.df['label'].nunique()}")
        print(f"Class distribution:\n{self.df['label'].value_counts().head(10)}")
        
        # Prepare features and target
        self.X = self.df[self.feature_names].values
        self.y = self.df['label'].values
        
        # Encode labels
        self.y_encoded = self.label_encoder.fit_transform(self.y)
        
        # Split the data
        self.X_train, self.X_test, self.y_train, self.y_test = train_test_split(
            self.X, self.y_encoded, test_size=0.2, random_state=42, stratify=self.y_encoded
        )
        
        # Scale features
        self.X_train_scaled = self.scaler.fit_transform(self.X_train)
        self.X_test_scaled = self.scaler.transform(self.X_test)
        
        print(f"Training set shape: {self.X_train.shape}")
        print(f"Test set shape: {self.X_test.shape}")
        
    def train_random_forest(self):
        """Train Random Forest model"""
        print("\nTraining Random Forest model...")
        self.rf_model = RandomForestClassifier(
            n_estimators=100,
            random_state=42,
            max_depth=10,
            min_samples_split=5,
            min_samples_leaf=2
        )
        
        self.rf_model.fit(self.X_train, self.y_train)
        
        # Evaluate
        y_pred_rf = self.rf_model.predict(self.X_test)
        accuracy_rf = accuracy_score(self.y_test, y_pred_rf)
        
        print(f"Random Forest Accuracy: {accuracy_rf:.4f}")
        print("\nRandom Forest Classification Report:")
        print(classification_report(self.y_test, y_pred_rf, 
                                  target_names=self.label_encoder.classes_))
        
        return accuracy_rf
        
    def train_neural_network(self):
        """Train Neural Network model"""
        print("\nTraining Neural Network model...")
        
        # Convert labels to categorical
        y_train_cat = to_categorical(self.y_train, num_classes=len(self.label_encoder.classes_))
        y_test_cat = to_categorical(self.y_test, num_classes=len(self.label_encoder.classes_))
        
        # Build model
        self.nn_model = Sequential([
            Dense(128, activation='relu', input_shape=(self.X_train_scaled.shape[1],)),
            Dropout(0.3),
            Dense(64, activation='relu'),
            Dropout(0.3),
            Dense(32, activation='relu'),
            Dropout(0.2),
            Dense(len(self.label_encoder.classes_), activation='softmax')
        ])
        
        self.nn_model.compile(
            optimizer='adam',
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        
        # Train model
        history = self.nn_model.fit(
            self.X_train_scaled, y_train_cat,
            epochs=100,
            batch_size=32,
            validation_data=(self.X_test_scaled, y_test_cat),
            verbose=0
        )
        
        # Evaluate
        y_pred_nn = self.nn_model.predict(self.X_test_scaled)
        y_pred_nn_classes = np.argmax(y_pred_nn, axis=1)
        accuracy_nn = accuracy_score(self.y_test, y_pred_nn_classes)
        
        print(f"Neural Network Accuracy: {accuracy_nn:.4f}")
        print("\nNeural Network Classification Report:")
        print(classification_report(self.y_test, y_pred_nn_classes, 
                                  target_names=self.label_encoder.classes_))
        
        return accuracy_nn, history
        
    def save_models(self):
        """Save trained models and preprocessing objects"""
        print("\nSaving models and preprocessing objects...")
        
        # Create models directory
        os.makedirs('models', exist_ok=True)
        
        # Save Random Forest model
        joblib.dump(self.rf_model, 'models/random_forest_model.pkl')
        
        # Save Neural Network model
        self.nn_model.save('models/neural_network_model.h5')
        
        # Save scaler and label encoder
        joblib.dump(self.scaler, 'models/scaler.pkl')
        joblib.dump(self.label_encoder, 'models/label_encoder.pkl')
        
        # Save feature names and class names
        model_info = {
            'feature_names': self.feature_names,
            'class_names': self.label_encoder.classes_.tolist(),
            'num_classes': len(self.label_encoder.classes_)
        }
        
        with open('models/model_info.json', 'w') as f:
            json.dump(model_info, f, indent=2)
            
        print("Models saved successfully!")
        
    def predict_crop(self, features, model_type='rf'):
        """Predict crop for given features"""
        if model_type == 'rf':
            if self.rf_model is None:
                raise ValueError("Random Forest model not trained yet")
            prediction = self.rf_model.predict([features])[0]
            probability = self.rf_model.predict_proba([features])[0]
        else:  # neural network
            if self.nn_model is None:
                raise ValueError("Neural Network model not trained yet")
            features_scaled = self.scaler.transform([features])
            prediction_proba = self.nn_model.predict(features_scaled)[0]
            prediction = np.argmax(prediction_proba)
            probability = prediction_proba
            
        crop_name = self.label_encoder.inverse_transform([prediction])[0]
        confidence = max(probability)
        
        return crop_name, confidence

def main():
    """Main training function"""
    print("=== Crop Recommendation Model Training ===")
    
    # Initialize trainer
    trainer = CropRecommendationTrainer()
    
    # Load and preprocess data
    trainer.load_and_preprocess_data()
    
    # Train models
    rf_accuracy = trainer.train_random_forest()
    nn_accuracy, history = trainer.train_neural_network()
    
    # Save models
    trainer.save_models()
    
    # Print summary
    print("\n=== Training Summary ===")
    print(f"Random Forest Accuracy: {rf_accuracy:.4f}")
    print(f"Neural Network Accuracy: {nn_accuracy:.4f}")
    
    # Test prediction
    print("\n=== Testing Prediction ===")
    sample_features = [90, 42, 43, 20.88, 82.00, 6.50, 202.94]  # Sample from dataset
    print(f"Sample features: {sample_features}")
    
    rf_crop, rf_conf = trainer.predict_crop(sample_features, 'rf')
    nn_crop, nn_conf = trainer.predict_crop(sample_features, 'nn')
    
    print(f"Random Forest prediction: {rf_crop} (confidence: {rf_conf:.4f})")
    print(f"Neural Network prediction: {nn_crop} (confidence: {nn_conf:.4f})")
    
    print("\nTraining completed successfully!")

if __name__ == "__main__":
    main()
