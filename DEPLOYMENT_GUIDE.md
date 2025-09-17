# Ultra Crop Recommender - Deployment Guide

## 🚀 Quick Start

### Prerequisites

- **Docker** (20.10+)
- **Docker Compose** (2.0+)
- **Git** (2.30+)
- **curl** (for testing)

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd harvest-enterprise-app
```

### 2. Environment Configuration

```bash
# Copy environment template
cp env.example .env

# Edit configuration
nano .env  # or use your preferred editor
```

**Important:** Update these values in `.env`:
- `OPENWEATHER_API_KEY` - Get from [OpenWeatherMap](https://openweathermap.org/api)
- `GOOGLE_MAPS_API_KEY` - Get from [Google Cloud Console](https://console.cloud.google.com/)
- `SECRET_KEY` - Generate a secure random key
- `POSTGRES_PASSWORD` - Use a strong password

### 3. Deploy

#### Option A: Using Deployment Scripts

**Linux/Mac:**
```bash
./deploy.sh local
```

**Windows:**
```cmd
deploy.bat local
```

#### Option B: Using Docker Compose Directly

```bash
# Build and start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Verify Deployment

```bash
# Test backend API
curl http://localhost:5020/health

# Test frontend
curl http://localhost:80

# Test recommendation endpoint
curl -X POST http://localhost:5020/ultra-recommend \
  -H "Content-Type: application/json" \
  -d '{"latitude": 28.6139, "longitude": 77.2090, "farm_size": 1.0, "irrigation_type": "drip", "language": "en"}'
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │   Database      │
│   (Flutter Web) │◄──►│   (Flask)       │◄──►│   (PostgreSQL)  │
│   Port: 80      │    │   Port: 5020    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx         │    │   Redis Cache   │    │   ML Models     │
│   (Reverse      │    │   Port: 6379    │    │   (Local Files) │
│    Proxy)       │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Services

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 80 | Flutter web application |
| Backend API | 5020 | Flask REST API |
| PostgreSQL | 5432 | Primary database |
| Redis | 6379 | Caching layer |
| Nginx | 443 | Reverse proxy (optional) |

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `API_HOST` | `0.0.0.0` | Backend API host |
| `API_PORT` | `5020` | Backend API port |
| `DEBUG` | `false` | Enable debug mode |
| `MODEL_PATH` | `./models` | ML models directory |
| `CACHE_TTL` | `3600` | Cache TTL in seconds |
| `OPENWEATHER_API_KEY` | - | Weather API key |
| `GOOGLE_MAPS_API_KEY` | - | Maps API key |
| `SECRET_KEY` | - | Flask secret key |
| `POSTGRES_PASSWORD` | - | Database password |

### Database Configuration

The application supports both PostgreSQL and SQLite:

**PostgreSQL (Production):**
```env
DATABASE_URL=postgresql://user:password@postgres:5432/ultra_crop
```

**SQLite (Development):**
```env
SQLITE_DATABASE_URL=sqlite:///ultra_crop_development.db
```

## 🚀 Deployment Options

### 1. Local Development

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f ultra-crop-api

# Stop services
docker-compose down
```

### 2. Production Deployment

#### Using Docker Compose

```bash
# Production environment
export ENVIRONMENT=production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

#### Using Kubernetes

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/

# Check deployment
kubectl get pods
kubectl get services
```

#### Using Cloud Platforms

**AWS ECS:**
```bash
# Build and push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker tag ultra-crop-api:latest <account>.dkr.ecr.us-east-1.amazonaws.com/ultra-crop-api:latest
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/ultra-crop-api:latest

# Deploy to ECS
aws ecs update-service --cluster ultra-crop-cluster --service ultra-crop-service --force-new-deployment
```

**Google Cloud Run:**
```bash
# Build and push to GCR
gcloud builds submit --tag gcr.io/PROJECT_ID/ultra-crop-api

# Deploy to Cloud Run
gcloud run deploy ultra-crop-api --image gcr.io/PROJECT_ID/ultra-crop-api --platform managed --region us-central1
```

## 🔍 Monitoring and Logs

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f ultra-crop-api

# Last 100 lines
docker-compose logs --tail=100 ultra-crop-api
```

### Health Checks

```bash
# Backend API health
curl http://localhost:5020/health

# Frontend health
curl http://localhost:80

# Database health
docker-compose exec postgres pg_isready -U ultra_crop_user
```

### Performance Monitoring

```bash
# Container stats
docker stats

# Resource usage
docker-compose top
```

## 🛠️ Troubleshooting

### Common Issues

**1. Port Already in Use**
```bash
# Check what's using the port
netstat -tulpn | grep :5020

# Kill the process
sudo kill -9 <PID>
```

**2. Database Connection Failed**
```bash
# Check database logs
docker-compose logs postgres

# Restart database
docker-compose restart postgres
```

**3. ML Models Not Loading**
```bash
# Check models directory
ls -la backend/models/

# Rebuild models
docker-compose exec ultra-crop-api python scripts/train_ultra_ml_models.py
```

**4. Frontend Not Loading**
```bash
# Check frontend logs
docker-compose logs ultra-crop-frontend

# Rebuild frontend
docker-compose build ultra-crop-frontend
```

### Debug Mode

```bash
# Enable debug mode
export DEBUG=true
docker-compose up -d

# View detailed logs
docker-compose logs -f ultra-crop-api
```

## 🔒 Security Considerations

### Production Security

1. **Change Default Passwords**
   ```bash
   # Generate secure passwords
   openssl rand -base64 32
   ```

2. **Use HTTPS**
   ```bash
   # Enable SSL in nginx
   # Update docker-compose.yml with SSL certificates
   ```

3. **Restrict Network Access**
   ```yaml
   # In docker-compose.yml
   networks:
     ultra-crop-network:
       driver: bridge
       ipam:
         config:
           - subnet: 172.20.0.0/16
   ```

4. **Regular Updates**
   ```bash
   # Update base images
   docker-compose pull
   docker-compose up -d
   ```

## 📊 Scaling

### Horizontal Scaling

```yaml
# docker-compose.scale.yml
version: '3.8'
services:
  ultra-crop-api:
    deploy:
      replicas: 3
    ports:
      - "5020-5022:5020"
```

```bash
# Scale services
docker-compose -f docker-compose.yml -f docker-compose.scale.yml up -d
```

### Load Balancing

```yaml
# nginx.conf
upstream backend {
    server ultra-crop-api:5020;
    server ultra-crop-api-2:5020;
    server ultra-crop-api-3:5020;
}
```

## 🔄 Backup and Recovery

### Database Backup

```bash
# Create backup
docker-compose exec postgres pg_dump -U ultra_crop_user ultra_crop > backup.sql

# Restore backup
docker-compose exec -T postgres psql -U ultra_crop_user ultra_crop < backup.sql
```

### Model Backup

```bash
# Backup models
tar -czf models-backup.tar.gz backend/models/

# Restore models
tar -xzf models-backup.tar.gz -C backend/
```

## 📈 Performance Optimization

### Database Optimization

```sql
-- Add indexes
CREATE INDEX idx_recommendations_location ON recommendations(latitude, longitude);
CREATE INDEX idx_recommendations_timestamp ON recommendations(created_at);
```

### Caching

```python
# Enable Redis caching
CACHE_TYPE = 'redis'
CACHE_REDIS_URL = 'redis://redis:6379/0'
```

### Resource Limits

```yaml
# docker-compose.yml
services:
  ultra-crop-api:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
```

## 🆘 Support

### Getting Help

1. **Check Logs**: Always check logs first
2. **Health Checks**: Verify all services are healthy
3. **Documentation**: Review this guide and API docs
4. **Issues**: Create an issue on GitHub

### Useful Commands

```bash
# Quick health check
curl -f http://localhost:5020/health && echo "✅ Backend OK" || echo "❌ Backend Failed"

# Full system status
docker-compose ps

# Resource usage
docker system df

# Clean up
docker system prune -f
```

---

## 🎯 Next Steps

1. **Set up monitoring** (Prometheus, Grafana)
2. **Configure CI/CD** (GitHub Actions, GitLab CI)
3. **Set up alerts** (PagerDuty, Slack)
4. **Implement backup strategy**
5. **Configure SSL certificates**
6. **Set up domain and DNS**

For more detailed information, see the [API Documentation](API_DOCS.md) and [Development Guide](DEVELOPMENT.md).
