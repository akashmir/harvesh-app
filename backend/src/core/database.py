"""
Unified Database Configuration for SIH 2025 Harvest Enterprise App
Uses PostgreSQL for robust multi-API database management
"""

import os
from sqlalchemy import create_engine, MetaData, Table, Column, String, Integer, Float, DateTime, Text, Boolean, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime
import logging

# Database configuration
DATABASE_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'harvest_enterprise'),
    'username': os.getenv('DB_USER', 'harvest_user'),
    'password': os.getenv('DB_PASSWORD', 'harvest_password')
}

# Create database URL
DATABASE_URL = f"postgresql://{DATABASE_CONFIG['username']}:{DATABASE_CONFIG['password']}@{DATABASE_CONFIG['host']}:{DATABASE_CONFIG['port']}/{DATABASE_CONFIG['database']}"

# Create engine
engine = create_engine(DATABASE_URL, echo=False, pool_pre_ping=True, pool_recycle=300)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database tables
class Field(Base):
    __tablename__ = "fields"
    
    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    description = Column(Text)
    area_hectares = Column(Float, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    soil_type = Column(String)
    soil_ph = Column(Float)
    soil_moisture = Column(Float)
    elevation = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    crop_history = relationship("CropHistory", back_populates="field")
    field_conditions = relationship("FieldCondition", back_populates="field")
    yield_predictions = relationship("YieldPrediction", back_populates="field")

class CropHistory(Base):
    __tablename__ = "crop_history"
    
    id = Column(String, primary_key=True)
    field_id = Column(String, ForeignKey("fields.id"), nullable=False)
    crop_name = Column(String, nullable=False)
    planting_date = Column(DateTime, nullable=False)
    harvesting_date = Column(DateTime)
    yield_kg = Column(Float)
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    field = relationship("Field", back_populates="crop_history")

class FieldCondition(Base):
    __tablename__ = "field_conditions"
    
    id = Column(String, primary_key=True)
    field_id = Column(String, ForeignKey("fields.id"), nullable=False)
    soil_ph = Column(Float)
    soil_moisture = Column(Float)
    temperature = Column(Float)
    humidity = Column(Float)
    recorded_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    field = relationship("Field", back_populates="field_conditions")

class YieldPrediction(Base):
    __tablename__ = "yield_predictions"
    
    id = Column(String, primary_key=True)
    field_id = Column(String, ForeignKey("fields.id"), nullable=False)
    crop_name = Column(String, nullable=False)
    predicted_yield = Column(Float, nullable=False)
    confidence_score = Column(Float, nullable=False)
    prediction_date = Column(DateTime, default=datetime.utcnow)
    soil_ph = Column(Float)
    soil_moisture = Column(Float)
    temperature = Column(Float)
    rainfall = Column(Float)
    area_hectares = Column(Float)
    season = Column(String)
    prediction_factors = Column(Text)  # JSON string
    actual_yield = Column(Float)
    accuracy_score = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    field = relationship("Field", back_populates="yield_predictions")

class WeatherData(Base):
    __tablename__ = "weather_data"
    
    id = Column(String, primary_key=True)
    field_id = Column(String, ForeignKey("fields.id"), nullable=False)
    date = Column(DateTime, nullable=False)
    temperature = Column(Float)
    humidity = Column(Float)
    rainfall = Column(Float)
    wind_speed = Column(Float)
    pressure = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    field = relationship("Field")

class MarketPrice(Base):
    __tablename__ = "market_prices"
    
    id = Column(String, primary_key=True)
    crop_name = Column(String, nullable=False)
    price_per_kg = Column(Float, nullable=False)
    market_name = Column(String)
    location = Column(String)
    date = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class DiseaseDetection(Base):
    __tablename__ = "disease_detections"
    
    id = Column(String, primary_key=True)
    field_id = Column(String, ForeignKey("fields.id"), nullable=False)
    crop_name = Column(String, nullable=False)
    disease_name = Column(String, nullable=False)
    confidence_score = Column(Float, nullable=False)
    image_path = Column(String)
    detection_date = Column(DateTime, default=datetime.utcnow)
    treatment_recommendations = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    field = relationship("Field")

class SustainabilityScore(Base):
    __tablename__ = "sustainability_scores"
    
    id = Column(String, primary_key=True)
    field_id = Column(String, ForeignKey("fields.id"), nullable=False)
    overall_score = Column(Float, nullable=False)
    soil_health_score = Column(Float)
    water_usage_score = Column(Float)
    biodiversity_score = Column(Float)
    carbon_footprint_score = Column(Float)
    assessment_date = Column(DateTime, default=datetime.utcnow)
    recommendations = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    field = relationship("Field")

class CropRotation(Base):
    __tablename__ = "crop_rotations"
    
    id = Column(String, primary_key=True)
    field_id = Column(String, ForeignKey("fields.id"), nullable=False)
    rotation_plan = Column(Text, nullable=False)  # JSON string
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime)
    status = Column(String, default="active")  # active, completed, cancelled
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    field = relationship("Field")

# Database utility functions
def get_db():
    """Get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_database():
    """Initialize database tables"""
    global engine, SessionLocal
    try:
        Base.metadata.create_all(bind=engine)
        logging.info("✅ Database tables created successfully")
        return True
    except Exception as e:
        logging.error(f"❌ Error creating database tables: {e}")
        # Fallback to SQLite if PostgreSQL is unavailable
        try:
            from sqlalchemy import create_engine as _create_engine
            sqlite_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'sih_2025_integrated.db'))
            sqlite_url = f"sqlite:///{sqlite_path}"
            engine = _create_engine(sqlite_url, echo=False, connect_args={"check_same_thread": False})
            SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
            Base.metadata.create_all(bind=engine)
            logging.warning(f"⚠️ Falling back to SQLite database at {sqlite_path}")
            return True
        except Exception as sqlite_error:
            logging.error(f"❌ SQLite fallback failed: {sqlite_error}")
            return False

def test_connection():
    """Test database connection"""
    try:
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        logging.info("✅ Database connection successful")
        return True
    except Exception as e:
        logging.error(f"❌ Database connection failed: {e}")
        return False

# Database health check
def health_check():
    """Comprehensive database health check"""
    try:
        # Test connection
        if not test_connection():
            return False
        
        # Check if tables exist
        db = SessionLocal()
        inspector = MetaData()
        inspector.reflect(bind=engine)
        tables = inspector.tables.keys()
        db.close()
        
        required_tables = [
            'fields', 'crop_history', 'field_conditions', 
            'yield_predictions', 'weather_data', 'market_prices',
            'disease_detections', 'sustainability_scores', 'crop_rotations'
        ]
        
        missing_tables = [table for table in required_tables if table not in tables]
        
        if missing_tables:
            logging.warning(f"⚠️ Missing tables: {missing_tables}")
            return False
        
        logging.info("✅ Database health check passed")
        return True
        
    except Exception as e:
        logging.error(f"❌ Database health check failed: {e}")
        return False

if __name__ == "__main__":
    # Initialize database when run directly
    print("🌾 Initializing Harvest Enterprise Database...")
    if init_database():
        print("✅ Database initialization completed successfully")
    else:
        print("❌ Database initialization failed")

