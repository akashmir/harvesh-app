#!/usr/bin/env python3
"""
Complete Ultra Crop Recommender System Startup
Starts both supporting APIs (SQLite-based) and Ultra Crop Recommender API
No PostgreSQL dependency required
"""

import os
import sys
import subprocess
import time
import signal
import threading
from pathlib import Path
import requests

# Add current directory to path
sys.path.append(os.path.dirname(__file__))

def print_banner():
    """Print startup banner"""
    banner = """
    ================================================================
                                                                   
             ULTRA CROP RECOMMENDER SYSTEM                        
                                                                   
        Advanced AI-Driven Crop Recommendation Platform           
                                                                   
      Features:                                                    
      * Satellite Soil Analysis (SQLite-based)                   
      * Advanced Weather Analytics                                
      * Ensemble ML Models (RF + NN + XGBoost)                   
      * Comprehensive Market Analysis                             
      * Sustainability Scoring                                    
      * Economic Analysis & ROI                                   
      * Topographic Analysis                                      
      * Vegetation Indices (NDVI/EVI)                            
      * Water Access Assessment                                   
      * Multi-language Support                                    
      * NO PostgreSQL Required - Uses SQLite                     
                                                                   
    ================================================================
    """
    print(banner)

def check_dependencies():
    """Check if required dependencies are installed"""
    print("\nChecking dependencies...")
    
    required_packages = [
        'flask', 'flask-cors', 'numpy', 'pandas', 'scikit-learn',
        'xgboost', 'requests'
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
            print(f"[OK] {package}")
        except ImportError:
            print(f"[MISSING] {package}")
            missing_packages.append(package)
    
    if missing_packages:
        print(f"\nInstalling missing packages: {', '.join(missing_packages)}")
        install_cmd = f"pip install {' '.join(missing_packages)}"
        result = subprocess.run(install_cmd, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            print("Dependencies installed successfully")
        else:
            print(f"Failed to install dependencies: {result.stderr}")
            return False
    
    return True

def train_ml_models():
    """Train the Ultra ML models if needed"""
    print("\nChecking ML Models...")
    
    models_dir = Path(__file__).parent / 'models'
    model_info_file = models_dir / 'model_info.json'
    
    if model_info_file.exists():
        print("ML models found, skipping training")
        return True
    
    # Train new models
    script_path = Path(__file__).parent / 'scripts' / 'train_ultra_ml_models.py'
    if script_path.exists():
        print("Training ML models...")
        result = subprocess.run([sys.executable, str(script_path)], 
                              capture_output=True, text=True, timeout=300)
        if result.returncode == 0:
            print("ML model training completed successfully")
            return True
        else:
            print(f"ML model training failed: {result.stderr}")
            print("Continuing with rule-based recommendations...")
            return True
    else:
        print("ML training script not found, using rule-based recommendations")
        return True

def start_supporting_apis():
    """Start supporting APIs in background"""
    print("\nStarting Supporting APIs (SQLite-based)...")
    
    script_path = Path(__file__).parent / 'simple_apis_sqlite.py'
    if script_path.exists():
        process = subprocess.Popen([sys.executable, str(script_path)], 
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Give APIs time to start
        time.sleep(3)
        
        # Test if APIs are responding
        test_endpoints = [
            ('http://localhost:5006/health', 'Satellite Soil API'),
            ('http://localhost:5005/health', 'Weather API'),
            ('http://localhost:5004/health', 'Market Price API'),
            ('http://localhost:5003/health', 'Yield Prediction API'),
            ('http://localhost:5009/health', 'Sustainability API'),
            ('http://localhost:5010/health', 'Crop Rotation API'),
            ('http://localhost:5007/health', 'Multilingual AI API')
        ]
        
        working_apis = 0
        for url, name in test_endpoints:
            try:
                response = requests.get(url, timeout=5)
                if response.status_code == 200:
                    print(f"[OK] {name}")
                    working_apis += 1
                else:
                    print(f"[ERROR] {name} - Status {response.status_code}")
            except:
                print(f"[ERROR] {name} - Not responding")
        
        if working_apis >= 5:
            print(f"Supporting APIs started successfully ({working_apis}/7 working)")
            return process
        else:
            print(f"Warning: Only {working_apis}/7 APIs are working")
            return process
    else:
        print("Supporting APIs script not found")
        return None

def start_ultra_api():
    """Start Ultra Crop Recommender API"""
    print("\nStarting Ultra Crop Recommender API...")
    
    api_script = Path(__file__).parent / 'ultra_crop_recommender_standalone.py'
    if api_script.exists():
        process = subprocess.Popen([sys.executable, str(api_script)], 
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Give server time to start
        time.sleep(3)
        
        # Check if it's running
        try:
            response = requests.get("http://localhost:5020/health", timeout=10)
            if response.status_code == 200:
                print("[OK] Ultra Crop Recommender API is healthy")
                return process
            else:
                print("[ERROR] Ultra Crop Recommender API health check failed")
                return None
        except:
            print("[ERROR] Ultra Crop Recommender API not responding")
            return None
    else:
        print("Ultra Crop Recommender API script not found")
        return None

def main():
    """Main startup function"""
    print_banner()
    
    # Store process references for cleanup
    processes = []
    
    def signal_handler(sig, frame):
        print("\n\nShutting down Ultra Crop Recommender System...")
        for process in processes:
            if process and process.poll() is None:
                process.terminate()
        print("Shutdown complete")
        sys.exit(0)
    
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Step 1: Check dependencies
        if not check_dependencies():
            print("Dependency check failed. Please install required packages.")
            return False
        
        # Step 2: Train ML models if needed
        if not train_ml_models():
            print("ML model setup failed, but continuing...")
        
        # Step 3: Start supporting APIs
        supporting_process = start_supporting_apis()
        if supporting_process:
            processes.append(supporting_process)
        
        # Step 4: Start Ultra Crop Recommender API
        ultra_process = start_ultra_api()
        if ultra_process:
            processes.append(ultra_process)
        else:
            print("Failed to start Ultra Crop Recommender API")
            return False
        
        # Display status
        print("\n" + "="*70)
        print("ULTRA CROP RECOMMENDER SYSTEM STARTED SUCCESSFULLY!")
        print("="*70)
        print("\nAPI Endpoints:")
        print("   Ultra Crop Recommender: http://localhost:5020")
        print("   Satellite Soil API:     http://localhost:5006")
        print("   Weather Integration:    http://localhost:5005")
        print("   Market Price API:       http://localhost:5004")
        print("   Yield Prediction:       http://localhost:5003")
        print("   Sustainability API:     http://localhost:5009")
        print("   Crop Rotation API:      http://localhost:5010")
        print("   Multilingual AI:        http://localhost:5007")
        
        print("\nWeb Access:")
        print("   Android Emulator: http://10.0.2.2:5020")
        print("   Local Browser:    http://localhost:5020")
        
        print("\nAPI Documentation:")
        print("   Health Check:     GET  /health")
        print("   Ultra Recommend:  POST /ultra-recommend")
        print("   Quick Recommend:  POST /ultra-recommend/quick")
        print("   Crop Database:    GET  /ultra-recommend/crops")
        
        print("\nSystem Status:")
        print("   Database:      SQLite (No PostgreSQL needed)")
        print("   ML Models:     Loaded/Rule-based")
        print("   Supporting APIs: Running")
        print("   Multi-lang:    Supported")
        print("   Mobile Ready:  Yes")
        
        print("\n" + "="*70)
        print("Press Ctrl+C to stop the system")
        print("="*70)
        
        # Keep main thread alive
        try:
            while True:
                time.sleep(1)
                
                # Check if main process died
                if processes and len(processes) > 1:
                    ultra_process = processes[-1]  # Last process is Ultra API
                    if ultra_process.poll() is not None:
                        print("Ultra Crop Recommender API terminated unexpectedly")
                        break
        except KeyboardInterrupt:
            pass
        
    except Exception as e:
        print(f"Startup failed: {e}")
        return False
    finally:
        # Cleanup
        signal_handler(None, None)

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
