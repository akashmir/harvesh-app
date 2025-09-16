#!/usr/bin/env python3
"""
Complete SIH 2025 System Deployment Script
Deploys both backend APIs and Flutter app to production
"""

import subprocess
import sys
import os
import json
import time
from pathlib import Path

class CompleteSystemDeployer:
    def __init__(self):
        self.project_id = "agrismart-sih2025-prod"
        self.region = "us-central1"
        self.apis = {
            "crop-api": {
                "file": "crop_api_production.py",
                "port": 8080,
                "memory": "1Gi",
                "cpu": "1",
                "max_instances": 10
            },
            "weather-api": {
                "file": "weather_integration_api.py",
                "port": 5005,
                "memory": "512Mi",
                "cpu": "0.5",
                "max_instances": 5
            },
            "market-api": {
                "file": "market_price_api.py",
                "port": 5004,
                "memory": "512Mi",
                "cpu": "0.5",
                "max_instances": 5
            },
            "soil-api": {
                "file": "satellite_soil_api.py",
                "port": 5006,
                "memory": "1Gi",
                "cpu": "1",
                "max_instances": 5
            },
            "multilingual-api": {
                "file": "multilingual_ai_api.py",
                "port": 5007,
                "memory": "1Gi",
                "cpu": "1",
                "max_instances": 5
            },
            "disease-api": {
                "file": "ai_disease_detection_api.py",
                "port": 5008,
                "memory": "2Gi",
                "cpu": "2",
                "max_instances": 3
            },
            "sustainability-api": {
                "file": "sustainability_scoring_api.py",
                "port": 5009,
                "memory": "1Gi",
                "cpu": "1",
                "max_instances": 5
            },
            "rotation-api": {
                "file": "crop_rotation_api.py",
                "port": 5010,
                "memory": "512Mi",
                "cpu": "0.5",
                "max_instances": 5
            },
            "offline-api": {
                "file": "offline_capability_api.py",
                "port": 5011,
                "memory": "512Mi",
                "cpu": "0.5",
                "max_instances": 5
            },
            "integrated-api": {
                "file": "sih_2025_integrated_api.py",
                "port": 5012,
                "memory": "2Gi",
                "cpu": "2",
                "max_instances": 3
            }
        }

    def create_dockerfile(self, api_name, api_config):
        """Create Dockerfile for each API"""
        dockerfile_content = f"""FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    gcc \\
    g++ \\
    curl \\
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy API file
COPY {api_config['file']} .

# Create necessary directories
RUN mkdir -p /app/data /app/models

# Expose port
EXPOSE {api_config['port']}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \\
    CMD curl -f http://localhost:{api_config['port']}/health || exit 1

# Run the API
CMD ["python", "{api_config['file']}"]
"""
        
        dockerfile_path = f"Dockerfile.{api_name}"
        with open(dockerfile_path, 'w') as f:
            f.write(dockerfile_content)
        return dockerfile_path

    def deploy_api(self, api_name, api_config):
        """Deploy a single API to Cloud Run"""
        print(f"🚀 Deploying {api_name}...")
        
        # Create Dockerfile
        dockerfile_path = self.create_dockerfile(api_name, api_config)
        
        # Build and deploy
        service_name = f"sih2025-{api_name}"
        image_name = f"gcr.io/{self.project_id}/{service_name}"
        
        try:
            # Build Docker image
            print(f"📦 Building Docker image for {api_name}...")
            subprocess.run([
                "gcloud", "builds", "submit",
                "--tag", image_name,
                "--file", dockerfile_path,
                "--project", self.project_id
            ], check=True)
            
            # Deploy to Cloud Run
            print(f"☁️ Deploying {api_name} to Cloud Run...")
            subprocess.run([
                "gcloud", "run", "deploy", service_name,
                "--image", image_name,
                "--platform", "managed",
                "--region", self.region,
                "--project", self.project_id,
                "--memory", api_config["memory"],
                "--cpu", api_config["cpu"],
                "--max-instances", str(api_config["max_instances"]),
                "--port", str(api_config["port"]),
                "--allow-unauthenticated",
                "--set-env-vars", f"PORT={api_config['port']}"
            ], check=True)
            
            # Get service URL
            result = subprocess.run([
                "gcloud", "run", "services", "describe", service_name,
                "--platform", "managed",
                "--region", self.region,
                "--project", self.project_id,
                "--format", "value(status.url)"
            ], capture_output=True, text=True, check=True)
            
            service_url = result.stdout.strip()
            print(f"✅ {api_name} deployed successfully: {service_url}")
            
            # Clean up Dockerfile
            os.remove(dockerfile_path)
            
            return service_url
            
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to deploy {api_name}: {e}")
            return None

    def deploy_all_apis(self):
        """Deploy all SIH 2025 APIs"""
        print("🎯 Starting SIH 2025 Backend Deployment")
        print("=" * 50)
        
        deployed_apis = {}
        
        for api_name, api_config in self.apis.items():
            service_url = self.deploy_api(api_name, api_config)
            if service_url:
                deployed_apis[api_name] = service_url
            time.sleep(10)  # Wait between deployments
        
        # Save deployment results
        with open("backend_deployment_results.json", "w") as f:
            json.dump(deployed_apis, f, indent=2)
        
        print("\n🎉 Backend Deployment Complete!")
        print("=" * 50)
        print("Deployed APIs:")
        for api_name, url in deployed_apis.items():
            print(f"  {api_name}: {url}")
        
        return deployed_apis

    def update_flutter_config(self, deployed_apis):
        """Update Flutter app configuration with production URLs"""
        print("\n📱 Updating Flutter app configuration...")
        
        env_content = f"""# SIH 2025 Production Environment Configuration

# App Configuration
APP_NAME=AgriSmart SIH 2025
APP_VERSION=2.0.0
DEBUG_MODE=false

# API Configuration
API_TIMEOUT=30
API_RETRY_COUNT=3
API_RETRY_DELAY=2000

# Core APIs (Production URLs)
CROP_API_BASE_URL={deployed_apis.get("crop-api", "https://sih2025-crop-api.run.app")}
WEATHER_INTEGRATION_API_BASE_URL={deployed_apis.get("weather-api", "https://sih2025-weather-api.run.app")}
MARKET_PRICE_API_BASE_URL={deployed_apis.get("market-api", "https://sih2025-market-api.run.app")}

# SIH 2025 Enhanced APIs (Production URLs)
SATELLITE_SOIL_API_BASE_URL={deployed_apis.get("soil-api", "https://sih2025-soil-api.run.app")}
MULTILINGUAL_AI_API_BASE_URL={deployed_apis.get("multilingual-api", "https://sih2025-multilingual-api.run.app")}
DISEASE_DETECTION_API_BASE_URL={deployed_apis.get("disease-api", "https://sih2025-disease-api.run.app")}
SUSTAINABILITY_SCORING_API_BASE_URL={deployed_apis.get("sustainability-api", "https://sih2025-sustainability-api.run.app")}
CROP_ROTATION_API_BASE_URL={deployed_apis.get("rotation-api", "https://sih2025-rotation-api.run.app")}
OFFLINE_CAPABILITY_API_BASE_URL={deployed_apis.get("offline-api", "https://sih2025-offline-api.run.app")}
SIH_2025_INTEGRATED_API_BASE_URL={deployed_apis.get("integrated-api", "https://sih2025-integrated-api.run.app")}

# Weather API
WEATHER_API_KEY=8382d6ea94ce19069453dc3ffb5e8518

# Firebase Configuration (Production)
FIREBASE_API_KEY=AIzaSyA2jnSHh16PjgcDOymvfRUfQNZt41U7VMk
FIREBASE_PROJECT_ID=agrismart-sih2025-prod
FIREBASE_APP_ID=1:273619012635:android:404c0b4e3786f0f1047cbe
FIREBASE_MESSAGING_SENDER_ID=273619012635
FIREBASE_STORAGE_BUCKET=agrismart-sih2025-prod.firebasestorage.app

# Blog API
BLOG_API_BASE_URL=https://sih2025-blog-api.run.app
"""
        
        with open("Flutter/env.production", "w") as f:
            f.write(env_content)
        
        print("✅ Flutter configuration updated!")

    def build_flutter_app(self):
        """Build Flutter app for production"""
        print("\n📱 Building Flutter App...")
        
        flutter_dir = Path("Flutter")
        if not flutter_dir.exists():
            print("❌ Flutter directory not found!")
            return False
        
        try:
            # Change to Flutter directory
            os.chdir(flutter_dir)
            
            # Get dependencies
            print("📦 Getting Flutter dependencies...")
            subprocess.run(["flutter", "pub", "get"], check=True)
            
            # Build for Android
            print("🤖 Building Android APK...")
            subprocess.run([
                "flutter", "build", "apk", 
                "--release", 
                "--flavor", "production"
            ], check=True)
            
            # Build for iOS
            print("🍎 Building iOS app...")
            subprocess.run([
                "flutter", "build", "ios", 
                "--release", 
                "--flavor", "production"
            ], check=True)
            
            # Build for Web
            print("🌐 Building Web app...")
            subprocess.run([
                "flutter", "build", "web", 
                "--release"
            ], check=True)
            
            print("✅ Flutter app built successfully!")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to build Flutter app: {e}")
            return False
        finally:
            # Change back to project root
            os.chdir("..")

    def deploy_flutter_web(self):
        """Deploy Flutter web app to Firebase Hosting"""
        print("\n🌐 Deploying Flutter Web App...")
        
        try:
            # Change to Flutter directory
            os.chdir("Flutter")
            
            # Deploy to Firebase
            print("🚀 Deploying to Firebase Hosting...")
            subprocess.run(["firebase", "deploy", "--only", "hosting"], check=True)
            
            print("✅ Flutter web app deployed successfully!")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to deploy Flutter web app: {e}")
            return False
        finally:
            # Change back to project root
            os.chdir("..")

    def run_final_tests(self):
        """Run final integration tests"""
        print("\n🧪 Running Final Integration Tests...")
        
        try:
            # Run the 100% test
            result = subprocess.run([
                "python", "test_final_100_percent.py"
            ], capture_output=True, text=True, check=True)
            
            print("✅ All tests passed!")
            print(result.stdout)
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ Tests failed: {e}")
            print(e.stdout)
            print(e.stderr)
            return False

    def deploy_complete_system(self):
        """Deploy the complete SIH 2025 system"""
        print("🚀 SIH 2025 COMPLETE SYSTEM DEPLOYMENT")
        print("=" * 60)
        print(f"🕐 Started at: {time.strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Step 1: Deploy Backend APIs
        print("📡 STEP 1: Deploying Backend APIs...")
        deployed_apis = self.deploy_all_apis()
        
        if not deployed_apis:
            print("❌ Backend deployment failed!")
            return False
        
        # Step 2: Update Flutter Configuration
        print("\n📱 STEP 2: Updating Flutter Configuration...")
        self.update_flutter_config(deployed_apis)
        
        # Step 3: Build Flutter App
        print("\n🔨 STEP 3: Building Flutter App...")
        if not self.build_flutter_app():
            print("❌ Flutter build failed!")
            return False
        
        # Step 4: Deploy Flutter Web
        print("\n🌐 STEP 4: Deploying Flutter Web App...")
        if not self.deploy_flutter_web():
            print("❌ Flutter web deployment failed!")
            return False
        
        # Step 5: Run Final Tests
        print("\n🧪 STEP 5: Running Final Tests...")
        if not self.run_final_tests():
            print("❌ Final tests failed!")
            return False
        
        # Success!
        print("\n🎉 DEPLOYMENT COMPLETE!")
        print("=" * 60)
        print("✅ Backend APIs: Deployed to Google Cloud Run")
        print("✅ Flutter App: Built for Android, iOS, and Web")
        print("✅ Web App: Deployed to Firebase Hosting")
        print("✅ Tests: All passing (100% success rate)")
        print()
        print("🌐 Web App: https://agrismart-sih2025-prod.web.app")
        print("📱 Android: Check build/app/outputs/bundle/productionRelease/")
        print("🍎 iOS: Check build/ios/Release-iphoneos/")
        print()
        print("🏆 SIH 2025 SYSTEM IS LIVE AND READY!")
        
        return True

def main():
    """Main deployment function"""
    print("🚀 SIH 2025 Complete System Deployment")
    print("=" * 60)
    
    # Check if gcloud is installed and authenticated
    try:
        subprocess.run(["gcloud", "auth", "list"], check=True, capture_output=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ Google Cloud CLI not found or not authenticated")
        print("Please install and authenticate gcloud CLI first")
        sys.exit(1)
    
    # Check if Flutter is installed
    try:
        subprocess.run(["flutter", "--version"], check=True, capture_output=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ Flutter not found!")
        print("Please install Flutter first")
        sys.exit(1)
    
    # Deploy complete system
    deployer = CompleteSystemDeployer()
    success = deployer.deploy_complete_system()
    
    if success:
        print("\n🎊 CONGRATULATIONS! SIH 2025 SYSTEM DEPLOYED SUCCESSFULLY!")
        sys.exit(0)
    else:
        print("\n❌ Deployment failed. Please check the errors above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
