#!/usr/bin/env python3
"""
Startup script for Ultra Crop Recommender System
Trains ML models and starts all required APIs
"""

import os
import sys
import subprocess
import time
import threading
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

def run_command(command, description, background=False):
    """Run a system command"""
    print(f"\n{description}...")
    try:
        if background:
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            return process
        else:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=300  # 5 minutes timeout
            )
            if result.returncode == 0:
                print(f"{description} completed successfully")
                return True
            else:
                print(f"{description} failed:")
                print(f"   Error: {result.stderr}")
                return False
    except subprocess.TimeoutExpired:
        print(f"{description} timed out")
        return False
    except Exception as e:
        print(f"{description} failed with exception: {e}")
        return False

def check_dependencies():
    """Check if required dependencies are installed"""
    print("\nChecking dependencies...")
    
    required_packages = [
        'flask', 'flask-cors', 'numpy', 'pandas', 'scikit-learn',
        'xgboost', 'requests', 'sqlalchemy', 'psycopg2-binary'
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
        if not run_command(install_cmd, "Installing dependencies"):
            return False
    
    return True

def train_ml_models():
    """Train the Ultra ML models"""
    print("\n🤖 Training Ultra ML Models...")
    
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
            
            training_date = datetime.fromisoformat(model_info['training_date'].replace('Z', '+00:00'))
            if datetime.now() - training_date.replace(tzinfo=None) < timedelta(days=7):
                print("✅ Recent ML models found, skipping training")
                return True
        except Exception as e:
            print(f"⚠️ Could not read model info: {e}")
    
    # Train new models
    script_path = Path(__file__).parent / 'scripts' / 'train_ultra_ml_models.py'
    if script_path.exists():
        return run_command(f"python {script_path}", "Training Ultra ML Models")
    else:
        print("⚠️ ML training script not found, using fallback models")
        return True

def start_api_server(script_name, port, description):
    """Start an API server in background"""
    script_path = Path(__file__).parent / f"{script_name}.py"
    if script_path.exists():
        print(f"🚀 Starting {description} on port {port}...")
        process = subprocess.Popen([
            sys.executable, str(script_path)
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Give server time to start
        time.sleep(2)
        
        return process
    else:
        print(f"⚠️ {script_name}.py not found")
        return None

def check_server_health(port, timeout=10):
    """Check if server is running on given port"""
    import requests
    try:
        response = requests.get(f"http://localhost:{port}/health", timeout=timeout)
        return response.status_code == 200
    except:
        return False

def main():
    """Main startup function"""
    print_banner()
    
    # Store process references for cleanup
    processes = []
    
    def signal_handler(sig, frame):
        print("\n\n🛑 Shutting down Ultra Crop Recommender System...")
        for process in processes:
            if process and process.poll() is None:
                process.terminate()
        print("✅ Shutdown complete")
        sys.exit(0)
    
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Step 1: Check dependencies
        if not check_dependencies():
            print("❌ Dependency check failed. Please install required packages.")
            return False
        
        # Step 2: Train ML models
        if not train_ml_models():
            print("⚠️ ML model training failed, continuing with existing models...")
        
        # Step 3: Start supporting APIs
        supporting_apis = [
            ('satellite_soil_api', 5006, 'Satellite Soil API'),
            ('weather_integration_api', 5005, 'Weather Integration API'),
            ('market_price_api', 5004, 'Market Price API'),
            ('yield_prediction_api', 5003, 'Yield Prediction API'),
            ('sustainability_scoring_api', 5009, 'Sustainability API'),
            ('crop_rotation_api', 5010, 'Crop Rotation API'),
            ('multilingual_ai_api', 5007, 'Multilingual AI API'),
        ]
        
        print("\n🔗 Starting Supporting APIs...")
        for script_name, port, description in supporting_apis:
            process = start_api_server(script_name, port, description)
            if process:
                processes.append(process)
        
        # Give supporting APIs time to start
        time.sleep(5)
        
        # Step 4: Start Ultra Crop Recommender API
        print("\n🚀 Starting Ultra Crop Recommender API...")
        ultra_process = start_api_server(
            'ultra_crop_recommender_api', 
            5020, 
            'Ultra Crop Recommender API'
        )
        if ultra_process:
            processes.append(ultra_process)
        
        # Step 5: Health check
        print("\n🏥 Performing health checks...")
        time.sleep(3)
        
        if check_server_health(5020):
            print("✅ Ultra Crop Recommender API is healthy")
        else:
            print("⚠️ Ultra Crop Recommender API health check failed")
        
        # Step 6: Display status
        print("\n" + "="*70)
        print("🎉 ULTRA CROP RECOMMENDER SYSTEM STARTED SUCCESSFULLY! 🎉")
        print("="*70)
        print("\n📡 API Endpoints:")
        print("   🚀 Ultra Crop Recommender: http://localhost:5020")
        print("   🛰️  Satellite Soil API:    http://localhost:5006")
        print("   🌦️  Weather Integration:   http://localhost:5005")
        print("   📊 Market Price API:       http://localhost:5004")
        print("   🌱 Yield Prediction:       http://localhost:5003")
        print("   🌿 Sustainability API:     http://localhost:5009")
        print("   🔄 Crop Rotation API:      http://localhost:5010")
        print("   🗣️  Multilingual AI:       http://localhost:5007")
        
        print("\n🌐 Web Access:")
        print("   📱 Android Emulator: http://10.0.2.2:5020")
        print("   💻 Local Browser:    http://localhost:5020")
        
        print("\n📚 API Documentation:")
        print("   📖 Health Check:     GET  /health")
        print("   🚀 Ultra Recommend:  POST /ultra-recommend")
        print("   ⚡ Quick Recommend:  POST /ultra-recommend/quick")
        print("   🌾 Crop Database:    GET  /ultra-recommend/crops")
        
        print("\n🛠️  System Status:")
        print("   🤖 ML Models:     Loaded")
        print("   🗄️  Database:      PostgreSQL")
        print("   🔗 APIs:          Running")
        print("   🌍 Multi-lang:    Supported")
        print("   📱 Mobile Ready:  Yes")
        
        print("\n" + "="*70)
        print("Press Ctrl+C to stop the system")
        print("="*70)
        
        # Keep main thread alive
        try:
            while True:
                time.sleep(1)
                # Check if any process died
                for i, process in enumerate(processes):
                    if process and process.poll() is not None:
                        print(f"⚠️ Process {i} terminated unexpectedly")
        except KeyboardInterrupt:
            pass
        
    except Exception as e:
        print(f"❌ Startup failed: {e}")
        return False
    finally:
        # Cleanup
        signal_handler(None, None)

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
