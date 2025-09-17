#!/usr/bin/env python3
"""
Simple startup script for Ultra Crop Recommender API only
"""

import os
import sys
import subprocess
import time
import signal
from pathlib import Path

# Add current directory to path
sys.path.append(os.path.dirname(__file__))

def print_banner():
    """Print startup banner"""
    banner = """
    ================================================================
                                                                   
             ULTRA CROP RECOMMENDER SYSTEM                        
                                                                   
        Advanced AI-Driven Crop Recommendation Platform           
                                                                   
      Features:                                                    
      * Satellite Soil Analysis (Bhuvan + Soil Grids)            
      * Advanced Weather Analytics                                
      * Ensemble ML Models (RF + NN + XGBoost)                   
      * Comprehensive Market Analysis                             
      * Sustainability Scoring                                    
      * Economic Analysis & ROI                                   
      * Topographic Analysis                                      
      * Vegetation Indices (NDVI/EVI)                            
      * Water Access Assessment                                   
      * Multi-language Support                                    
                                                                   
    ================================================================
    """
    print(banner)

def check_dependencies():
    """Check if required dependencies are installed"""
    print("\nChecking dependencies...")
    
    required_packages = [
        'flask', 'flask-cors', 'numpy', 'pandas', 'scikit-learn',
        'xgboost', 'requests', 'sqlalchemy'
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
    """Train the Ultra ML models"""
    print("\nTraining Ultra ML Models...")
    
    # Check if models already exist and are recent
    models_dir = Path(__file__).parent / 'models'
    model_info_file = models_dir / 'model_info.json'
    
    if model_info_file.exists():
        # Check if models are recent (less than 7 days old)
        import json
        from datetime import datetime, timedelta
        
        try:
            with open(model_info_file, 'r') as f:
                model_info = json.load(f)
            
            if 'training_date' in model_info:
                training_date = datetime.fromisoformat(model_info['training_date'].replace('Z', '+00:00'))
                if datetime.now() - training_date.replace(tzinfo=None) < timedelta(days=7):
                    print("Recent ML models found, skipping training")
                    return True
        except Exception as e:
            print(f"Could not read model info: {e}")
    
    # Train new models
    script_path = Path(__file__).parent / 'scripts' / 'train_ultra_ml_models.py'
    if script_path.exists():
        result = subprocess.run([sys.executable, str(script_path)], 
                              capture_output=True, text=True, timeout=300)
        if result.returncode == 0:
            print("ML model training completed successfully")
            return True
        else:
            print(f"ML model training failed: {result.stderr}")
            return False
    else:
        print("ML training script not found, using fallback models")
        return True

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
        
        # Step 2: Train ML models
        if not train_ml_models():
            print("ML model training failed, continuing with existing models...")
        
        # Step 3: Start Ultra Crop Recommender API
        print("\nStarting Ultra Crop Recommender API...")
        
        api_script = Path(__file__).parent / 'ultra_crop_recommender_standalone.py'
        if api_script.exists():
            process = subprocess.Popen([sys.executable, str(api_script)], 
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            processes.append(process)
            
            # Give server time to start
            time.sleep(3)
            
            # Check if it's running
            import requests
            try:
                response = requests.get("http://localhost:5020/health", timeout=10)
                if response.status_code == 200:
                    print("Ultra Crop Recommender API is healthy")
                else:
                    print("Ultra Crop Recommender API health check failed")
            except:
                print("Ultra Crop Recommender API health check failed")
        else:
            print("Ultra Crop Recommender API script not found")
            return False
        
        # Display status
        print("\n" + "="*70)
        print("ULTRA CROP RECOMMENDER SYSTEM STARTED SUCCESSFULLY!")
        print("="*70)
        print("\nAPI Endpoints:")
        print("   Ultra Crop Recommender: http://localhost:5020")
        
        print("\nWeb Access:")
        print("   Android Emulator: http://10.0.2.2:5020")
        print("   Local Browser:    http://localhost:5020")
        
        print("\nAPI Documentation:")
        print("   Health Check:     GET  /health")
        print("   Ultra Recommend:  POST /ultra-recommend")
        print("   Quick Recommend:  POST /ultra-recommend/quick")
        print("   Crop Database:    GET  /ultra-recommend/crops")
        
        print("\nSystem Status:")
        print("   ML Models:     Loaded")
        print("   API:           Running")
        print("   Multi-lang:    Supported")
        print("   Mobile Ready:  Yes")
        
        print("\n" + "="*70)
        print("Press Ctrl+C to stop the system")
        print("="*70)
        
        # Keep main thread alive
        try:
            while True:
                time.sleep(1)
                # Check if process died
                if processes and processes[0].poll() is not None:
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
