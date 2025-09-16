"""
Simple Crop Recommendation Model Training
Uses only basic libraries to train a simple model
"""

import csv
import json
import pickle
import os
from collections import Counter
import random

def load_data(filename='Crop_recommendation.csv'):
    """Load data from CSV file"""
    data = []
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        for row in reader:
            data.append({
                'N': float(row['N']),
                'P': float(row['P']),
                'K': float(row['K']),
                'temperature': float(row['temperature']),
                'humidity': float(row['humidity']),
                'ph': float(row['ph']),
                'rainfall': float(row['rainfall']),
                'label': row['label']
            })
    return data

def simple_classifier(train_data, test_data):
    """Simple rule-based classifier"""
    # Calculate average values for each crop
    crop_averages = {}
    for crop in set(item['label'] for item in train_data):
        crop_data = [item for item in train_data if item['label'] == crop]
        if crop_data:
            crop_averages[crop] = {
                'N': sum(item['N'] for item in crop_data) / len(crop_data),
                'P': sum(item['P'] for item in crop_data) / len(crop_data),
                'K': sum(item['K'] for item in crop_data) / len(crop_data),
                'temperature': sum(item['temperature'] for item in crop_data) / len(crop_data),
                'humidity': sum(item['humidity'] for item in crop_data) / len(crop_data),
                'ph': sum(item['ph'] for item in crop_data) / len(crop_data),
                'rainfall': sum(item['rainfall'] for item in crop_data) / len(crop_data),
            }
    
    predictions = []
    for item in test_data:
        features = [item['N'], item['P'], item['K'], item['temperature'], 
                   item['humidity'], item['ph'], item['rainfall']]
        
        # Find closest match based on Euclidean distance
        best_crop = None
        best_distance = float('inf')
        
        for crop, averages in crop_averages.items():
            distance = sum((features[i] - list(averages.values())[i]) ** 2 
                          for i in range(len(features))) ** 0.5
            if distance < best_distance:
                best_distance = distance
                best_crop = crop
        
        predictions.append(best_crop)
    
    return predictions

def train_and_evaluate():
    """Train and evaluate the model"""
    print("Loading data...")
    data = load_data()
    print(f"Loaded {len(data)} samples")
    
    # Get unique crops
    crops = list(set(item['label'] for item in data))
    print(f"Found {len(crops)} different crops: {crops[:10]}...")
    
    # Split data (80% train, 20% test)
    random.shuffle(data)
    split_idx = int(0.8 * len(data))
    train_data = data[:split_idx]
    test_data = data[split_idx:]
    
    print(f"Training set: {len(train_data)} samples")
    print(f"Test set: {len(test_data)} samples")
    
    # Train model
    print("Training simple classifier...")
    predictions = simple_classifier(train_data, test_data)
    
    # Calculate accuracy
    correct = sum(1 for i, pred in enumerate(predictions) 
                  if pred == test_data[i]['label'])
    accuracy = correct / len(test_data)
    
    print(f"Accuracy: {accuracy:.4f} ({correct}/{len(test_data)})")
    
    # Show some predictions
    print("\nSample predictions:")
    for i in range(min(10, len(test_data))):
        actual = test_data[i]['label']
        predicted = predictions[i]
        print(f"Actual: {actual}, Predicted: {predicted}, Match: {actual == predicted}")
    
    # Save model info
    model_info = {
        'crops': crops,
        'accuracy': accuracy,
        'total_samples': len(data),
        'train_samples': len(train_data),
        'test_samples': len(test_data)
    }
    
    # Create models directory
    os.makedirs('models', exist_ok=True)
    
    # Save model info
    with open('models/simple_model_info.json', 'w') as f:
        json.dump(model_info, f, indent=2)
    
    print(f"\nModel info saved to models/simple_model_info.json")
    print("Training completed!")
    
    return model_info

if __name__ == "__main__":
    train_and_evaluate()
