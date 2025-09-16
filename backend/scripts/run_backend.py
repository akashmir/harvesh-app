"""
Backend Runner Script
Trains models and starts the Flask API server.
"""

import os
import sys
import subprocess
import time

def install_requirements():
    """Install required packages"""
    print("Installing required packages...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
        print("✅ Requirements installed successfully!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Error installing requirements: {e}")
        return False

def train_models():
    """Train the crop recommendation models"""
    print("\nTraining crop recommendation models...")
    try:
        from train_model import main as train_main
        train_main()
        print("✅ Models trained successfully!")
        return True
    except Exception as e:
        print(f"❌ Error training models: {e}")
        return False

def start_api():
    """Start the Flask API server"""
    print("\nStarting Flask API server...")
    try:
        from crop_api import app
        print("✅ API server starting on http://localhost:5000")
        print("Press Ctrl+C to stop the server")
        app.run(host='0.0.0.0', port=5000, debug=True)
    except Exception as e:
        print(f"❌ Error starting API: {e}")

def main():
    """Main function"""
    print("=== Crop Recommendation Backend Setup ===")
    
    # Check if dataset exists
    if not os.path.exists('Crop_recommendation.csv'):
        print("❌ Dataset file 'Crop_recommendation.csv' not found!")
        print("Please ensure the dataset file is in the current directory.")
        return
    
    # Install requirements
    if not install_requirements():
        return
    
    # Train models
    if not train_models():
        return
    
    # Start API
    start_api()

if __name__ == "__main__":
    main()
