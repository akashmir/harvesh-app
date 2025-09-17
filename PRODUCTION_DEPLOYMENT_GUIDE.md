# 🚀 Production Deployment Guide - Market Price API

## Overview
This guide will help you deploy the Market Price API to production, making it accessible from anywhere and ready for release.

## 🎯 Deployment Options

### Option 1: Railway (Recommended - Free Tier Available)
Railway provides easy deployment with automatic HTTPS and custom domains.

#### Steps:
1. **Sign up at [Railway.app](https://railway.app)**
2. **Connect your GitHub repository**
3. **Deploy the backend:**
   ```bash
   # In your project root
   cd backend
   railway login
   railway init
   railway up
   ```

4. **Set environment variables in Railway dashboard:**
   - `FLASK_ENV=production`
   - `PORT=5004`
   - `HOST=0.0.0.0`

5. **Your API will be available at:**
   ```
   https://your-app-name.up.railway.app
   ```

### Option 2: Render (Free Tier Available)
Render provides simple deployment with automatic builds.

#### Steps:
1. **Sign up at [Render.com](https://render.com)**
2. **Create a new Web Service**
3. **Connect your GitHub repository**
4. **Configure build settings:**
   - **Build Command:** `pip install -r requirements_production.txt`
   - **Start Command:** `gunicorn --bind 0.0.0.0:$PORT --workers 4 --timeout 120 production_market_price_api:app`
   - **Environment:** Python 3.11

5. **Set environment variables:**
   - `FLASK_ENV=production`
   - `PORT=5004`

6. **Deploy!**

### Option 3: Heroku (Paid)
Heroku provides robust deployment with add-ons.

#### Steps:
1. **Install Heroku CLI**
2. **Login and create app:**
   ```bash
   heroku login
   heroku create your-market-price-api
   ```

3. **Set environment variables:**
   ```bash
   heroku config:set FLASK_ENV=production
   heroku config:set PORT=5004
   ```

4. **Deploy:**
   ```bash
   git add .
   git commit -m "Deploy to production"
   git push heroku main
   ```

### Option 4: Docker Deployment (Self-hosted)
Deploy using Docker on your own server.

#### Steps:
1. **Build and run with Docker Compose:**
   ```bash
   # Make scripts executable (Linux/Mac)
   chmod +x deploy_production.sh
   ./deploy_production.sh

   # Or on Windows
   deploy_production.bat
   ```

2. **Or manually:**
   ```bash
   docker-compose -f docker-compose.production.yml up --build -d
   ```

## 🔧 Local Development Setup

### For Android Emulator:
```bash
# Start the production API locally
cd backend
python production_market_price_api.py
```

### For Physical Device:
1. **Find your computer's IP address:**
   - Windows: `ipconfig`
   - Mac/Linux: `ifconfig`

2. **Update frontend config:**
   ```dart
   // In frontend/lib/config/app_config.dart
   return 'http://YOUR_IP_ADDRESS:5004';
   ```

## 📱 Frontend Configuration

### Environment Variables
Create `frontend/.env` file:
```env
# Production API URLs
MARKET_PRICE_API_BASE_URL=https://your-deployed-api.com
CROP_API_BASE_URL=https://your-crop-api.com
WEATHER_API_KEY=your-weather-api-key
```

### Update App Config
The frontend is already configured to use production URLs by default. For local development, you can override with environment variables.

## 🧪 Testing Your Deployment

### 1. Health Check
```bash
curl https://your-api-url.com/health
```

### 2. Test Market Prices
```bash
curl "https://your-api-url.com/price/current?crop=Rice"
```

### 3. Test Location-based Prices
```bash
curl "https://your-api-url.com/prices/location-based?latitude=28.6139&longitude=77.2090"
```

### 4. Test Mandis
```bash
curl https://your-api-url.com/mandis
```

## 🔒 Production Security

### 1. Environment Variables
- Never commit `.env` files
- Use strong secret keys
- Rotate API keys regularly

### 2. CORS Configuration
The API is configured with `CORS(app)` for development. For production, restrict origins:
```python
CORS(app, origins=["https://your-frontend-domain.com"])
```

### 3. Rate Limiting
Consider adding rate limiting for production:
```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)
```

## 📊 Monitoring & Logging

### 1. Health Monitoring
The API includes a `/health` endpoint for monitoring:
```bash
curl https://your-api-url.com/health
```

### 2. Logs
View logs in your deployment platform:
- **Railway:** Dashboard → Logs
- **Render:** Dashboard → Logs
- **Heroku:** `heroku logs --tail`

### 3. Database
The API uses SQLite for simplicity. For production scale, consider:
- PostgreSQL
- MySQL
- MongoDB

## 🚀 Performance Optimization

### 1. Caching
Add Redis caching for frequently accessed data:
```python
from flask_caching import Cache

cache = Cache(app, config={'CACHE_TYPE': 'redis'})

@cache.memoize(timeout=300)
def get_crop_prices(crop_name):
    # Expensive operation
    pass
```

### 2. Database Indexing
The production API includes database indexes for better performance.

### 3. CDN
Use a CDN for static assets and API responses.

## 🔄 CI/CD Pipeline

### GitHub Actions Example
```yaml
name: Deploy to Production
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Railway
        run: railway up
```

## 📈 Scaling

### Horizontal Scaling
- Use load balancers
- Deploy multiple instances
- Use container orchestration (Kubernetes)

### Vertical Scaling
- Increase server resources
- Optimize database queries
- Add caching layers

## 🆘 Troubleshooting

### Common Issues:

1. **CORS Errors:**
   - Check CORS configuration
   - Verify frontend URL in CORS origins

2. **Database Errors:**
   - Check database file permissions
   - Verify database initialization

3. **Port Issues:**
   - Ensure port 5004 is available
   - Check firewall settings

4. **Environment Variables:**
   - Verify all required variables are set
   - Check variable names and values

### Debug Mode:
For debugging, set `DEBUG=true` in environment variables.

## 📞 Support

If you encounter issues:
1. Check the logs
2. Verify environment variables
3. Test endpoints individually
4. Check network connectivity

## 🎉 Success!

Once deployed, your Market Price API will be:
- ✅ **Accessible globally** via HTTPS
- ✅ **Production-ready** with proper error handling
- ✅ **Scalable** with Docker and cloud deployment
- ✅ **Monitored** with health checks and logging
- ✅ **Secure** with proper CORS and environment configuration

Your app is now ready for production release! 🚀
