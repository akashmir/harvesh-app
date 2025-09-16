# Harvest Backend Services

Enterprise-grade backend services for the Harvest agricultural management platform.

## 🏗️ Architecture

```
backend/
├── src/
│   ├── api/                    # REST API endpoints
│   │   ├── crop_recommendation_api.py
│   │   ├── weather_api.py
│   │   ├── market_price_api.py
│   │   ├── yield_prediction_api.py
│   │   ├── field_management_api.py
│   │   ├── soil_analysis_api.py
│   │   ├── multilingual_api.py
│   │   ├── disease_detection_api.py
│   │   ├── sustainability_api.py
│   │   ├── crop_rotation_api.py
│   │   ├── offline_api.py
│   │   ├── crop_calendar_api.py
│   │   └── integrated_api.py
│   ├── core/                   # Core business logic
│   │   ├── model_training.py
│   │   ├── data_manager.py
│   │   └── performance_optimizer.py
│   ├── models/                 # Data models and ML models
│   ├── services/               # Business services
│   └── utils/                  # Utility functions
├── data/                       # Database files
├── tests/                      # Test suites
├── scripts/                    # Deployment and utility scripts
├── config/                     # Configuration files
└── requirements.txt            # Python dependencies
```

## 🚀 Quick Start

### Installation
```bash
# Install dependencies
pip install -r requirements.txt

# Initialize database
python scripts/setup_database.py

# Start development server
python scripts/run_backend.py
```

### Production Deployment
```bash
# Deploy to production
python scripts/deploy_production.py

# Start production server
python scripts/start_system.py
```

## 📊 API Services

### Core Services
- **Crop Recommendation API** (Port 5000) - ML-based crop suggestions
- **Weather API** (Port 5005) - Real-time weather data
- **Market Price API** (Port 5004) - Market price information
- **Yield Prediction API** (Port 5003) - Yield forecasting
- **Field Management API** (Port 5002) - Field tracking and management

### Advanced Services
- **Soil Analysis API** (Port 5006) - Satellite soil data
- **Multilingual API** (Port 5007) - Language processing
- **Disease Detection API** (Port 5008) - Plant disease identification
- **Sustainability API** (Port 5009) - Environmental impact
- **Crop Rotation API** (Port 5010) - Rotation planning
- **Offline API** (Port 5011) - Offline capabilities
- **Integrated API** (Port 5012) - Unified service

## 🔧 Configuration

### Environment Variables
```bash
# Core Configuration
DEBUG_MODE=false
API_TIMEOUT=30
LOG_LEVEL=INFO

# Database
DATABASE_URL=sqlite:///data/harvest.db

# External APIs
WEATHER_API_KEY=your_weather_api_key
SOIL_API_KEY=your_soil_api_key

# Security
JWT_SECRET_KEY=your_jwt_secret
CORS_ORIGINS=http://localhost:3000,https://yourdomain.com
```

### API Configuration
Each API service can be configured independently:
- Port assignment
- Database connections
- External service integrations
- Rate limiting
- Authentication requirements

## 🧪 Testing

### Run All Tests
```bash
python -m pytest tests/ -v
```

### Run Specific Test Suites
```bash
# API tests
python -m pytest tests/test_api_*.py

# Integration tests
python -m pytest tests/test_integration_*.py

# Performance tests
python -m pytest tests/test_performance_*.py
```

### Test Coverage
```bash
python -m pytest --cov=src tests/
```

## 📈 Performance Monitoring

### Metrics
- API response times
- Database query performance
- Memory usage
- CPU utilization
- Error rates

### Monitoring Tools
- Built-in performance dashboard
- Log aggregation
- Health check endpoints
- Real-time metrics

## 🔒 Security

### Authentication
- JWT-based token authentication
- Role-based access control
- API key management

### Data Protection
- Input validation and sanitization
- SQL injection prevention
- XSS protection
- Rate limiting

### Compliance
- GDPR compliance
- Data encryption at rest
- Secure data transmission
- Audit logging

## 🚀 Deployment

### Docker Deployment
```bash
# Build image
docker build -t harvest-backend .

# Run container
docker run -p 5000:5000 harvest-backend
```

### Kubernetes Deployment
```bash
# Apply configurations
kubectl apply -f deployments/k8s/

# Check status
kubectl get pods -l app=harvest-backend
```

### Cloud Deployment
- Google Cloud Run
- AWS ECS
- Azure Container Instances

## 📊 Database Schema

### Core Tables
- `users` - User accounts and profiles
- `fields` - Field information and metadata
- `crops` - Crop data and recommendations
- `weather_data` - Weather information
- `market_prices` - Market price data

### Analytics Tables
- `recommendations` - Crop recommendations
- `yield_predictions` - Yield forecasts
- `soil_analysis` - Soil property data
- `disease_reports` - Disease detection results

## 🔧 Development

### Code Style
- Follow PEP 8 guidelines
- Use type hints
- Write comprehensive docstrings
- Maintain test coverage > 80%

### Git Workflow
1. Create feature branch
2. Make changes
3. Add tests
4. Run linting and tests
5. Submit pull request

### API Documentation
- OpenAPI/Swagger specifications
- Interactive API explorer
- Code examples
- Error code reference

## 🆘 Troubleshooting

### Common Issues
- Database connection errors
- API timeout issues
- Memory leaks
- Performance degradation

### Debug Mode
```bash
# Enable debug logging
export DEBUG_MODE=true
export LOG_LEVEL=DEBUG
python scripts/run_backend.py
```

### Health Checks
```bash
# Check API health
curl http://localhost:5000/health

# Check all services
python scripts/quick_status_check.py
```

## 📚 Additional Resources

- [API Documentation](docs/api.md)
- [Database Schema](docs/database.md)
- [Deployment Guide](docs/deployment.md)
- [Performance Tuning](docs/performance.md)
- [Security Guidelines](docs/security.md)

---

**Harvest Backend** - Enterprise-grade agricultural intelligence services.
