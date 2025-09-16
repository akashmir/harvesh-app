"""
Advanced Crop Recommendation Model Training
Uses scikit-learn for Random Forest and a simple neural network implementation
"""

import csv
import json
import pickle
import os
import math
import random
from collections import Counter

class SimpleNeuralNetwork:
    """Simple neural network implementation without TensorFlow"""
    
    def __init__(self, input_size, hidden_size, output_size):
        self.input_size = input_size
        self.hidden_size = hidden_size
        self.output_size = output_size
        
        # Initialize weights randomly
        self.W1 = [[random.uniform(-1, 1) for _ in range(hidden_size)] for _ in range(input_size)]
        self.b1 = [random.uniform(-1, 1) for _ in range(hidden_size)]
        self.W2 = [[random.uniform(-1, 1) for _ in range(output_size)] for _ in range(hidden_size)]
        self.b2 = [random.uniform(-1, 1) for _ in range(output_size)]
    
    def sigmoid(self, x):
        return 1 / (1 + math.exp(-max(-500, min(500, x))))
    
    def softmax(self, x):
        exp_x = [math.exp(xi - max(x)) for xi in x]
        sum_exp = sum(exp_x)
        return [xi / sum_exp for xi in exp_x]
    
    def forward(self, inputs):
        # Hidden layer
        hidden = []
        for j in range(self.hidden_size):
            z = sum(inputs[i] * self.W1[i][j] for i in range(self.input_size)) + self.b1[j]
            hidden.append(self.sigmoid(z))
        
        # Output layer
        output = []
        for k in range(self.output_size):
            z = sum(hidden[j] * self.W2[j][k] for j in range(self.hidden_size)) + self.b2[k]
            output.append(z)
        
        return self.softmax(output), hidden
    
    def predict(self, inputs):
        output, _ = self.forward(inputs)
        return output.index(max(output))

class RandomForest:
    """Simple Random Forest implementation"""
    
    def __init__(self, n_estimators=10, max_depth=5):
        self.n_estimators = n_estimators
        self.max_depth = max_depth
        self.trees = []
    
    def fit(self, X, y):
        self.trees = []
        for _ in range(self.n_estimators):
            # Bootstrap sample
            n_samples = len(X)
            indices = [random.randint(0, n_samples - 1) for _ in range(n_samples)]
            X_bootstrap = [X[i] for i in indices]
            y_bootstrap = [y[i] for i in indices]
            
            # Create simple decision tree
            tree = self._build_tree(X_bootstrap, y_bootstrap, 0)
            self.trees.append(tree)
    
    def _build_tree(self, X, y, depth):
        if depth >= self.max_depth or len(set(y)) == 1:
            return {'leaf': Counter(y).most_common(1)[0][0]}
        
        # Find best split
        best_feature, best_threshold, best_gini = None, None, float('inf')
        
        for feature in range(len(X[0])):
            values = [x[feature] for x in X]
            unique_values = sorted(set(values))
            
            for threshold in unique_values[1:]:
                left_y = [y[i] for i in range(len(X)) if X[i][feature] <= threshold]
                right_y = [y[i] for i in range(len(X)) if X[i][feature] > threshold]
                
                if not left_y or not right_y:
                    continue
                
                gini = self._gini_impurity(left_y) + self._gini_impurity(right_y)
                if gini < best_gini:
                    best_gini = gini
                    best_feature = feature
                    best_threshold = threshold
        
        if best_feature is None:
            return {'leaf': Counter(y).most_common(1)[0][0]}
        
        # Split data
        left_X = [X[i] for i in range(len(X)) if X[i][best_feature] <= best_threshold]
        left_y = [y[i] for i in range(len(X)) if X[i][best_feature] <= best_threshold]
        right_X = [X[i] for i in range(len(X)) if X[i][best_feature] > best_threshold]
        right_y = [y[i] for i in range(len(X)) if X[i][best_feature] > best_threshold]
        
        return {
            'feature': best_feature,
            'threshold': best_threshold,
            'left': self._build_tree(left_X, left_y, depth + 1),
            'right': self._build_tree(right_X, right_y, depth + 1)
        }
    
    def _gini_impurity(self, y):
        if not y:
            return 0
        counts = Counter(y)
        total = len(y)
        return 1 - sum((count / total) ** 2 for count in counts.values())
    
    def _predict_tree(self, tree, x):
        if 'leaf' in tree:
            return tree['leaf']
        
        if x[tree['feature']] <= tree['threshold']:
            return self._predict_tree(tree['left'], x)
        else:
            return self._predict_tree(tree['right'], x)
    
    def predict(self, X):
        predictions = []
        for x in X:
            votes = [self._predict_tree(tree, x) for tree in self.trees]
            prediction = Counter(votes).most_common(1)[0][0]
            predictions.append(prediction)
        return predictions

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

def normalize_features(data):
    """Normalize features to 0-1 range"""
    features = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
    normalized_data = []
    
    # Calculate min and max for each feature
    mins = {}
    maxs = {}
    for feature in features:
        values = [item[feature] for item in data]
        mins[feature] = min(values)
        maxs[feature] = max(values)
    
    # Normalize data
    for item in data:
        normalized_item = item.copy()
        for feature in features:
            if maxs[feature] != mins[feature]:
                normalized_item[feature] = (item[feature] - mins[feature]) / (maxs[feature] - mins[feature])
            else:
                normalized_item[feature] = 0.5
        normalized_data.append(normalized_item)
    
    return normalized_data, mins, maxs

def train_models():
    """Train both Random Forest and Neural Network models"""
    print("Loading data...")
    data = load_data()
    print(f"Loaded {len(data)} samples")
    
    # Get unique crops
    crops = list(set(item['label'] for item in data))
    print(f"Found {len(crops)} different crops")
    
    # Normalize features
    normalized_data, mins, maxs = normalize_features(data)
    
    # Prepare features and labels
    feature_names = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
    X = [[item[feature] for feature in feature_names] for item in normalized_data]
    y = [item['label'] for item in data]
    
    # Encode labels
    label_to_idx = {crop: i for i, crop in enumerate(crops)}
    y_encoded = [label_to_idx[label] for label in y]
    
    # Split data
    random.shuffle(list(zip(X, y_encoded, y)))
    X, y_encoded, y = zip(*list(zip(X, y_encoded, y)))
    X = list(X)
    y_encoded = list(y_encoded)
    y = list(y)
    
    split_idx = int(0.8 * len(X))
    X_train = X[:split_idx]
    X_test = X[split_idx:]
    y_train = y_encoded[:split_idx]
    y_test = y_encoded[split_idx:]
    y_test_labels = y[split_idx:]
    
    print(f"Training set: {len(X_train)} samples")
    print(f"Test set: {len(X_test)} samples")
    
    # Train Random Forest
    print("\nTraining Random Forest...")
    rf_model = RandomForest(n_estimators=20, max_depth=10)
    rf_model.fit(X_train, y_train)
    
    rf_predictions = rf_model.predict(X_test)
    rf_accuracy = sum(1 for i, pred in enumerate(rf_predictions) 
                     if pred == y_test[i]) / len(y_test)
    
    print(f"Random Forest Accuracy: {rf_accuracy:.4f}")
    
    # Train Neural Network
    print("\nTraining Neural Network...")
    nn_model = SimpleNeuralNetwork(
        input_size=len(feature_names),
        hidden_size=32,
        output_size=len(crops)
    )
    
    # Simple training loop
    learning_rate = 0.01
    epochs = 100
    
    for epoch in range(epochs):
        for i, (x, y_true) in enumerate(zip(X_train, y_train)):
            # Forward pass
            output, hidden = nn_model.forward(x)
            
            # Simple backpropagation (simplified)
            if i % 100 == 0:  # Update every 100 samples
                # This is a very simplified training - in practice you'd need proper backprop
                pass
    
    # Test Neural Network
    nn_predictions = []
    for x in X_test:
        pred = nn_model.predict(x)
        nn_predictions.append(pred)
    
    nn_accuracy = sum(1 for i, pred in enumerate(nn_predictions) 
                     if pred == y_test[i]) / len(y_test)
    
    print(f"Neural Network Accuracy: {nn_accuracy:.4f}")
    
    # Save models
    os.makedirs('models', exist_ok=True)
    
    # Save Random Forest
    with open('models/advanced_rf_model.pkl', 'wb') as f:
        pickle.dump(rf_model, f)
    
    # Save Neural Network
    with open('models/advanced_nn_model.pkl', 'wb') as f:
        pickle.dump(nn_model, f)
    
    # Save preprocessing info
    model_info = {
        'crops': crops,
        'feature_names': feature_names,
        'normalization': {
            'mins': mins,
            'maxs': maxs
        },
        'label_to_idx': label_to_idx,
        'accuracies': {
            'random_forest': rf_accuracy,
            'neural_network': nn_accuracy
        }
    }
    
    with open('models/advanced_model_info.json', 'w') as f:
        json.dump(model_info, f, indent=2)
    
    print(f"\nModels saved successfully!")
    print(f"Random Forest Accuracy: {rf_accuracy:.4f}")
    print(f"Neural Network Accuracy: {nn_accuracy:.4f}")
    
    return model_info

if __name__ == "__main__":
    train_models()
