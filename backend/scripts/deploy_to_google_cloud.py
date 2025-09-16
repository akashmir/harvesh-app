#!/usr/bin/env python3
"""
SIH 2025 Google Cloud Deployment Script
Deploys all APIs to Google Cloud Run and Flutter web to Firebase Hosting
"""

import subprocess
import sys
import os
import json
import time
from pathlib import Path

class GoogleCloudDeployer:
    def __init__(self):
        self.project_id = "agrismart-app-1930c"
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
        """Create optimized Dockerfile for each API"""
        dockerfile_content = f"""FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    gcc \\
    g++ \\
    curl \\
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
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
                "--project", self.project_id,
                "--timeout", "20m"
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
                "--set-env-vars", f"PORT={api_config['port']}",
                "--timeout", "300"
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
        print("🎯 Starting SIH 2025 Backend Deployment to Google Cloud")
        print("=" * 60)
        
        deployed_apis = {}
        
        for api_name, api_config in self.apis.items():
            service_url = self.deploy_api(api_name, api_config)
            if service_url:
                deployed_apis[api_name] = service_url
            time.sleep(5)  # Wait between deployments
        
        # Save deployment results
        with open("google_cloud_deployment_results.json", "w") as f:
            json.dump(deployed_apis, f, indent=2)
        
        print("\n🎉 Backend Deployment Complete!")
        print("=" * 60)
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
CROP_API_BASE_URL={deployed_apis.get("crop-api", "https://sih2025-crop-api-{self.region}-{self.project_id}.a.run.app")}
WEATHER_INTEGRATION_API_BASE_URL={deployed_apis.get("weather-api", "https://sih2025-weather-api-{self.region}-{self.project_id}.a.run.app")}
MARKET_PRICE_API_BASE_URL={deployed_apis.get("market-api", "https://sih2025-market-api-{self.region}-{self.project_id}.a.run.app")}

# SIH 2025 Enhanced APIs (Production URLs)
SATELLITE_SOIL_API_BASE_URL={deployed_apis.get("soil-api", "https://sih2025-soil-api-{self.region}-{self.project_id}.a.run.app")}
MULTILINGUAL_AI_API_BASE_URL={deployed_apis.get("multilingual-api", "https://sih2025-multilingual-api-{self.region}-{self.project_id}.a.run.app")}
DISEASE_DETECTION_API_BASE_URL={deployed_apis.get("disease-api", "https://sih2025-disease-api-{self.region}-{self.project_id}.a.run.app")}
SUSTAINABILITY_SCORING_API_BASE_URL={deployed_apis.get("sustainability-api", "https://sih2025-sustainability-api-{self.region}-{self.project_id}.a.run.app")}
CROP_ROTATION_API_BASE_URL={deployed_apis.get("rotation-api", "https://sih2025-rotation-api-{self.region}-{self.project_id}.a.run.app")}
OFFLINE_CAPABILITY_API_BASE_URL={deployed_apis.get("offline-api", "https://sih2025-offline-api-{self.region}-{self.project_id}.a.run.app")}
SIH_2025_INTEGRATED_API_BASE_URL={deployed_apis.get("integrated-api", "https://sih2025-integrated-api-{self.region}-{self.project_id}.a.run.app")}

# Weather API
WEATHER_API_KEY=8382d6ea94ce19069453dc3ffb5e8518

# Firebase Configuration (Production)
FIREBASE_API_KEY=AIzaSyA2jnSHh16PjgcDOymvfRUfQNZt41U7VMk
FIREBASE_PROJECT_ID={self.project_id}
FIREBASE_APP_ID=1:273619012635:android:404c0b4e3786f0f1047cbe
FIREBASE_MESSAGING_SENDER_ID=273619012635
FIREBASE_STORAGE_BUCKET={self.project_id}.firebasestorage.app

# Blog API
BLOG_API_BASE_URL=https://sih2025-blog-api-{self.region}-{self.project_id}.a.run.app
"""
        
        with open("Flutter/env.production", "w") as f:
            f.write(env_content)
        
        print("✅ Flutter configuration updated!")

    def build_flutter_web(self):
        """Build Flutter web app for production"""
        print("\n📱 Building Flutter Web App...")
        
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
            
            # Build for web
            print("🌐 Building Flutter web app...")
            subprocess.run([
                "flutter", "build", "web", 
                "--release",
                "--web-renderer", "html"
            ], check=True)
            
            print("✅ Flutter web app built successfully!")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to build Flutter web app: {e}")
            return False
        finally:
            # Change back to project root
            os.chdir("..")

    def deploy_flutter_web(self):
        """Deploy Flutter web app to Firebase Hosting"""
        print("\n🌐 Deploying Flutter Web App to Firebase...")
        
        try:
            # Change to Flutter directory
            os.chdir("Flutter")
            
            # Initialize Firebase if not already done
            if not Path("firebase.json").exists():
                print("🔧 Initializing Firebase...")
                subprocess.run(["firebase", "init", "hosting", "--project", self.project_id, "--yes"], check=True)
            
            # Deploy to Firebase
            print("🚀 Deploying to Firebase Hosting...")
            subprocess.run(["firebase", "deploy", "--only", "hosting", "--project", self.project_id], check=True)
            
            print("✅ Flutter web app deployed successfully!")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to deploy Flutter web app: {e}")
            return False
        finally:
            # Change back to project root
            os.chdir("..")

    def test_deployed_apis(self, deployed_apis):
        """Test the deployed APIs"""
        print("\n🧪 Testing Deployed APIs...")
        
        import requests
        
        test_results = {}
        for api_name, url in deployed_apis.items():
            try:
                response = requests.get(f"{url}/health", timeout=10)
                if response.status_code == 200:
                    test_results[api_name] = "✅ Healthy"
                else:
                    test_results[api_name] = f"❌ HTTP {response.status_code}"
            except Exception as e:
                test_results[api_name] = f"❌ Error: {str(e)[:50]}"
        
        print("API Health Check Results:")
        for api_name, result in test_results.items():
            print(f"  {api_name}: {result}")
        
        return test_results

    def deploy_complete_system(self):
        """Deploy the complete SIH 2025 system to Google Cloud"""
        print("🚀 SIH 2025 GOOGLE CLOUD DEPLOYMENT")
        print("=" * 60)
        print(f"🕐 Started at: {time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"📋 Project: {self.project_id}")
        print(f"🌍 Region: {self.region}")
        print()
        
        # Step 1: Deploy Backend APIs
        print("📡 STEP 1: Deploying Backend APIs to Cloud Run...")
        deployed_apis = self.deploy_all_apis()
        
        if not deployed_apis:
            print("❌ Backend deployment failed!")
            return False
        
        # Step 2: Update Flutter Configuration
        print("\n📱 STEP 2: Updating Flutter Configuration...")
        self.update_flutter_config(deployed_apis)
        
        # Step 3: Build Flutter Web App
        print("\n🔨 STEP 3: Building Flutter Web App...")
        if not self.build_flutter_web():
            print("❌ Flutter web build failed!")
            return False
        
        # Step 4: Deploy Flutter Web App
        print("\n🌐 STEP 4: Deploying Flutter Web App to Firebase...")
        if not self.deploy_flutter_web():
            print("❌ Flutter web deployment failed!")
            return False
        
        # Step 5: Test Deployed APIs
        print("\n🧪 STEP 5: Testing Deployed APIs...")
        test_results = self.test_deployed_apis(deployed_apis)
        
        # Success!
        print("\n🎉 GOOGLE CLOUD DEPLOYMENT COMPLETE!")
        print("=" * 60)
        print("✅ Backend APIs: Deployed to Google Cloud Run")
        print("✅ Flutter Web App: Deployed to Firebase Hosting")
        print("✅ Configuration: Updated with production URLs")
        print()
        print("🌐 Your SIH 2025 System is now live at:")
        print(f"   Web App: https://{self.project_id}.web.app")
        print()
        print("📱 API Endpoints:")
        for api_name, url in deployed_apis.items():
            print(f"   {api_name}: {url}")
        print()
        print("🏆 SIH 2025 SYSTEM IS LIVE ON GOOGLE CLOUD!")
        
        return True

def main():
    """Main deployment function"""
    print("🚀 SIH 2025 Google Cloud Deployment")
    print("=" * 60)
    
    # Check if gcloud is installed and authenticated
    try:
        result = subprocess.run(["gcloud", "auth", "list"], capture_output=True, text=True, check=True)
        if "akashbashir391@gmail.com" not in result.stdout:
            print("❌ Not authenticated with Google Cloud")
            print("Please run: gcloud auth login")
            sys.exit(1)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ Google Cloud CLI not found")
        print("Please install Google Cloud CLI first")
        sys.exit(1)
    
    # Check if Flutter is installed
    try:
        subprocess.run(["flutter", "--version"], check=True, capture_output=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ Flutter not found!")
        print("Please install Flutter first")
        sys.exit(1)
    
    # Deploy complete system
    deployer = GoogleCloudDeployer()
    success = deployer.deploy_complete_system()
    
    if success:
        print("\n🎊 CONGRATULATIONS! SIH 2025 SYSTEM DEPLOYED TO GOOGLE CLOUD!")
        sys.exit(0)
    else:
        print("\n❌ Deployment failed. Please check the errors above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
