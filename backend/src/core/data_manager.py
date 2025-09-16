"""
Comprehensive Data Management System
Handles data validation, backup, consistency, and analytics
"""

import sqlite3
import json
import os
import logging
import hashlib
import csv
import pandas as pd
from datetime import datetime, timezone
from typing import Dict, List, Optional, Any, Tuple
import threading
import time
import shutil
from pathlib import Path
import pickle
import numpy as np
from dataclasses import dataclass, asdict
from enum import Enum
import uuid

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DataType(Enum):
    CROP_RECOMMENDATION = "crop_recommendation"
    DISEASE_DETECTION = "disease_detection"
    WEATHER_QUERY = "weather_query"
    USER_PROFILE = "user_profile"
    SYSTEM_METRICS = "system_metrics"
    API_REQUEST = "api_request"

class DataStatus(Enum):
    ACTIVE = "active"
    ARCHIVED = "archived"
    DELETED = "deleted"
    PENDING = "pending"

@dataclass
class DataRecord:
    id: str
    data_type: DataType
    data: Dict[str, Any]
    metadata: Dict[str, Any]
    status: DataStatus
    created_at: datetime
    updated_at: datetime
    version: int
    checksum: str

class DataValidator:
    """Comprehensive data validation system"""
    
    @staticmethod
    def validate_crop_recommendation(data: Dict[str, Any]) -> Tuple[bool, List[str]]:
        """Validate crop recommendation data"""
        errors = []
        
        required_fields = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
        for field in required_fields:
            if field not in data:
                errors.append(f"Missing required field: {field}")
            elif not isinstance(data[field], (int, float)):
                errors.append(f"Field {field} must be a number")
        
        # Range validation
        validations = [
            ('N', 0, 200, 'Nitrogen must be between 0 and 200 kg/ha'),
            ('P', 0, 200, 'Phosphorus must be between 0 and 200 kg/ha'),
            ('K', 0, 200, 'Potassium must be between 0 and 200 kg/ha'),
            ('temperature', 0, 50, 'Temperature must be between 0 and 50°C'),
            ('humidity', 0, 100, 'Humidity must be between 0 and 100%'),
            ('ph', 0, 14, 'pH must be between 0 and 14'),
            ('rainfall', 0, 500, 'Rainfall must be between 0 and 500 mm')
        ]
        
        for field, min_val, max_val, error_msg in validations:
            if field in data and isinstance(data[field], (int, float)):
                if not (min_val <= data[field] <= max_val):
                    errors.append(error_msg)
        
        return len(errors) == 0, errors
    
    @staticmethod
    def validate_user_profile(data: Dict[str, Any]) -> Tuple[bool, List[str]]:
        """Validate user profile data"""
        errors = []
        
        if 'email' not in data or not data['email']:
            errors.append("Email is required")
        elif '@' not in data['email']:
            errors.append("Invalid email format")
        
        if 'uid' not in data or not data['uid']:
            errors.append("User ID is required")
        
        if 'farmSize' in data and data['farmSize'] is not None:
            if not isinstance(data['farmSize'], (int, float)) or data['farmSize'] < 0:
                errors.append("Farm size must be a positive number")
        
        return len(errors) == 0, errors
    
    @staticmethod
    def validate_disease_detection(data: Dict[str, Any]) -> Tuple[bool, List[str]]:
        """Validate disease detection data"""
        errors = []
        
        if 'imagePath' not in data or not data['imagePath']:
            errors.append("Image path is required")
        
        if 'confidence' not in data:
            errors.append("Confidence score is required")
        elif not isinstance(data['confidence'], (int, float)) or not (0 <= data['confidence'] <= 1):
            errors.append("Confidence must be between 0 and 1")
        
        return len(errors) == 0, errors

class DataBackupManager:
    """Handles data backup and recovery"""
    
    def __init__(self, backup_dir: str = "backups"):
        self.backup_dir = Path(backup_dir)
        self.backup_dir.mkdir(exist_ok=True)
        self.retention_days = 30
    
    def create_backup(self, data_type: DataType, data: List[DataRecord]) -> str:
        """Create a backup of data"""
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        backup_file = self.backup_dir / f"{data_type.value}_{timestamp}.json"
        
        backup_data = {
            'data_type': data_type.value,
            'timestamp': timestamp,
            'record_count': len(data),
            'records': [asdict(record) for record in data]
        }
        
        with open(backup_file, 'w') as f:
            json.dump(backup_data, f, indent=2, default=str)
        
        logger.info(f"Created backup: {backup_file} with {len(data)} records")
        return str(backup_file)
    
    def restore_backup(self, backup_file: str) -> List[DataRecord]:
        """Restore data from backup"""
        with open(backup_file, 'r') as f:
            backup_data = json.load(f)
        
        records = []
        for record_data in backup_data['records']:
            record = DataRecord(
                id=record_data['id'],
                data_type=DataType(record_data['data_type']),
                data=record_data['data'],
                metadata=record_data['metadata'],
                status=DataStatus(record_data['status']),
                created_at=datetime.fromisoformat(record_data['created_at']),
                updated_at=datetime.fromisoformat(record_data['updated_at']),
                version=record_data['version'],
                checksum=record_data['checksum']
            )
            records.append(record)
        
        logger.info(f"Restored {len(records)} records from {backup_file}")
        return records
    
    def cleanup_old_backups(self):
        """Remove old backup files"""
        cutoff_date = datetime.now(timezone.utc).timestamp() - (self.retention_days * 24 * 3600)
        
        for backup_file in self.backup_dir.glob("*.json"):
            if backup_file.stat().st_mtime < cutoff_date:
                backup_file.unlink()
                logger.info(f"Removed old backup: {backup_file}")

class DataAnalytics:
    """Data analytics and insights"""
    
    def __init__(self, db_manager):
        self.db_manager = db_manager
    
    def get_usage_statistics(self, days: int = 30) -> Dict[str, Any]:
        """Get usage statistics for the last N days"""
        cutoff_date = datetime.now(timezone.utc).timestamp() - (days * 24 * 3600)
        
        stats = {
            'total_requests': 0,
            'crop_recommendations': 0,
            'disease_detections': 0,
            'weather_queries': 0,
            'unique_users': set(),
            'popular_crops': {},
            'error_rate': 0,
            'avg_response_time': 0
        }
        
        # Get all records from the last N days
        records = self.db_manager.get_records_since(cutoff_date)
        
        for record in records:
            stats['total_requests'] += 1
            
            if record.data_type == DataType.CROP_RECOMMENDATION:
                stats['crop_recommendations'] += 1
                if 'recommended_crop' in record.data:
                    crop = record.data['recommended_crop']
                    stats['popular_crops'][crop] = stats['popular_crops'].get(crop, 0) + 1
            elif record.data_type == DataType.DISEASE_DETECTION:
                stats['disease_detections'] += 1
            elif record.data_type == DataType.WEATHER_QUERY:
                stats['weather_queries'] += 1
            
            if 'user_id' in record.metadata:
                stats['unique_users'].add(record.metadata['user_id'])
            
            if 'response_time' in record.metadata:
                stats['avg_response_time'] += record.metadata['response_time']
        
        # Calculate averages
        if stats['total_requests'] > 0:
            stats['avg_response_time'] /= stats['total_requests']
            stats['error_rate'] = sum(1 for r in records if r.status == DataStatus.DELETED) / stats['total_requests']
        
        stats['unique_users'] = len(stats['unique_users'])
        stats['popular_crops'] = dict(sorted(stats['popular_crops'].items(), key=lambda x: x[1], reverse=True)[:10])
        
        return stats
    
    def get_data_quality_report(self) -> Dict[str, Any]:
        """Generate data quality report"""
        all_records = self.db_manager.get_all_records()
        
        report = {
            'total_records': len(all_records),
            'data_types': {},
            'validation_errors': 0,
            'missing_checksums': 0,
            'duplicate_records': 0,
            'old_records': 0
        }
        
        checksums = set()
        cutoff_date = datetime.now(timezone.utc).timestamp() - (365 * 24 * 3600)  # 1 year
        
        for record in all_records:
            # Count by data type
            data_type = record.data_type.value
            report['data_types'][data_type] = report['data_types'].get(data_type, 0) + 1
            
            # Check for validation errors
            if record.status == DataStatus.DELETED:
                report['validation_errors'] += 1
            
            # Check for missing checksums
            if not record.checksum:
                report['missing_checksums'] += 1
            
            # Check for duplicates
            if record.checksum in checksums:
                report['duplicate_records'] += 1
            else:
                checksums.add(record.checksum)
            
            # Check for old records
            if record.created_at.timestamp() < cutoff_date:
                report['old_records'] += 1
        
        return report

class DatabaseManager:
    """Main database management system"""
    
    def __init__(self, db_path: str = "crop_data.db"):
        self.db_path = db_path
        self.validator = DataValidator()
        self.backup_manager = DataBackupManager()
        self.analytics = DataAnalytics(self)
        self.lock = threading.Lock()
        
        self._init_database()
        self._start_background_tasks()
    
    def _init_database(self):
        """Initialize database schema"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS data_records (
                    id TEXT PRIMARY KEY,
                    data_type TEXT NOT NULL,
                    data TEXT NOT NULL,
                    metadata TEXT NOT NULL,
                    status TEXT NOT NULL,
                    created_at TIMESTAMP NOT NULL,
                    updated_at TIMESTAMP NOT NULL,
                    version INTEGER NOT NULL,
                    checksum TEXT NOT NULL
                )
            """)
            
            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_data_type ON data_records(data_type)
            """)
            
            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_created_at ON data_records(created_at)
            """)
            
            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_status ON data_records(status)
            """)
    
    def _start_background_tasks(self):
        """Start background maintenance tasks"""
        def cleanup_task():
            while True:
                time.sleep(3600)  # Run every hour
                self.backup_manager.cleanup_old_backups()
                self._cleanup_old_records()
        
        cleanup_thread = threading.Thread(target=cleanup_task, daemon=True)
        cleanup_thread.start()
    
    def _cleanup_old_records(self):
        """Remove old deleted records"""
        cutoff_date = datetime.now(timezone.utc).timestamp() - (30 * 24 * 3600)  # 30 days
        
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                DELETE FROM data_records 
                WHERE status = ? AND created_at < ?
            """, (DataStatus.DELETED.value, cutoff_date))
    
    def _calculate_checksum(self, data: Dict[str, Any]) -> str:
        """Calculate checksum for data integrity"""
        data_str = json.dumps(data, sort_keys=True)
        return hashlib.md5(data_str.encode()).hexdigest()
    
    def save_record(self, data_type: DataType, data: Dict[str, Any], 
                   metadata: Dict[str, Any] = None) -> str:
        """Save a new data record with validation"""
        with self.lock:
            # Validate data
            if data_type == DataType.CROP_RECOMMENDATION:
                is_valid, errors = self.validator.validate_crop_recommendation(data)
            elif data_type == DataType.USER_PROFILE:
                is_valid, errors = self.validator.validate_user_profile(data)
            elif data_type == DataType.DISEASE_DETECTION:
                is_valid, errors = self.validator.validate_disease_detection(data)
            else:
                is_valid, errors = True, []
            
            if not is_valid:
                raise ValueError(f"Data validation failed: {errors}")
            
            # Create record
            record_id = str(uuid.uuid4())
            now = datetime.now(timezone.utc)
            checksum = self._calculate_checksum(data)
            
            record = DataRecord(
                id=record_id,
                data_type=data_type,
                data=data,
                metadata=metadata or {},
                status=DataStatus.ACTIVE,
                created_at=now,
                updated_at=now,
                version=1,
                checksum=checksum
            )
            
            # Save to database
            with sqlite3.connect(self.db_path) as conn:
                conn.execute("""
                    INSERT INTO data_records 
                    (id, data_type, data, metadata, status, created_at, updated_at, version, checksum)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    record.id,
                    record.data_type.value,
                    json.dumps(record.data),
                    json.dumps(record.metadata),
                    record.status.value,
                    record.created_at.isoformat(),
                    record.updated_at.isoformat(),
                    record.version,
                    record.checksum
                ))
            
            logger.info(f"Saved record {record_id} of type {data_type.value}")
            return record_id
    
    def get_record(self, record_id: str) -> Optional[DataRecord]:
        """Get a specific record by ID"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                SELECT * FROM data_records WHERE id = ?
            """, (record_id,))
            
            row = cursor.fetchone()
            if not row:
                return None
            
            return DataRecord(
                id=row[0],
                data_type=DataType(row[1]),
                data=json.loads(row[2]),
                metadata=json.loads(row[3]),
                status=DataStatus(row[4]),
                created_at=datetime.fromisoformat(row[5]),
                updated_at=datetime.fromisoformat(row[6]),
                version=row[7],
                checksum=row[8]
            )
    
    def get_records_by_type(self, data_type: DataType, limit: int = 100) -> List[DataRecord]:
        """Get records by data type"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                SELECT * FROM data_records 
                WHERE data_type = ? AND status = ?
                ORDER BY created_at DESC
                LIMIT ?
            """, (data_type.value, DataStatus.ACTIVE.value, limit))
            
            records = []
            for row in cursor.fetchall():
                record = DataRecord(
                    id=row[0],
                    data_type=DataType(row[1]),
                    data=json.loads(row[2]),
                    metadata=json.loads(row[3]),
                    status=DataStatus(row[4]),
                    created_at=datetime.fromisoformat(row[5]),
                    updated_at=datetime.fromisoformat(row[6]),
                    version=row[7],
                    checksum=row[8]
                )
                records.append(record)
            
            return records
    
    def get_records_since(self, timestamp: float) -> List[DataRecord]:
        """Get records created since timestamp"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                SELECT * FROM data_records 
                WHERE created_at >= ? AND status = ?
                ORDER BY created_at DESC
            """, (datetime.fromtimestamp(timestamp).isoformat(), DataStatus.ACTIVE.value))
            
            records = []
            for row in cursor.fetchall():
                record = DataRecord(
                    id=row[0],
                    data_type=DataType(row[1]),
                    data=json.loads(row[2]),
                    metadata=json.loads(row[3]),
                    status=DataStatus(row[4]),
                    created_at=datetime.fromisoformat(row[5]),
                    updated_at=datetime.fromisoformat(row[6]),
                    version=row[7],
                    checksum=row[8]
                )
                records.append(record)
            
            return records
    
    def get_all_records(self) -> List[DataRecord]:
        """Get all active records"""
        return self.get_records_since(0)
    
    def update_record(self, record_id: str, data: Dict[str, Any], 
                     metadata: Dict[str, Any] = None) -> bool:
        """Update an existing record"""
        with self.lock:
            record = self.get_record(record_id)
            if not record:
                return False
            
            # Validate updated data
            if record.data_type == DataType.CROP_RECOMMENDATION:
                is_valid, errors = self.validator.validate_crop_recommendation(data)
            elif record.data_type == DataType.USER_PROFILE:
                is_valid, errors = self.validator.validate_user_profile(data)
            elif record.data_type == DataType.DISEASE_DETECTION:
                is_valid, errors = self.validator.validate_disease_detection(data)
            else:
                is_valid, errors = True, []
            
            if not is_valid:
                raise ValueError(f"Data validation failed: {errors}")
            
            # Update record
            now = datetime.now(timezone.utc)
            checksum = self._calculate_checksum(data)
            
            with sqlite3.connect(self.db_path) as conn:
                conn.execute("""
                    UPDATE data_records 
                    SET data = ?, metadata = ?, updated_at = ?, version = version + 1, checksum = ?
                    WHERE id = ?
                """, (
                    json.dumps(data),
                    json.dumps(metadata or record.metadata),
                    now.isoformat(),
                    checksum,
                    record_id
                ))
            
            logger.info(f"Updated record {record_id}")
            return True
    
    def delete_record(self, record_id: str, soft_delete: bool = True) -> bool:
        """Delete a record (soft or hard delete)"""
        with self.lock:
            if soft_delete:
                with sqlite3.connect(self.db_path) as conn:
                    conn.execute("""
                        UPDATE data_records 
                        SET status = ?, updated_at = ?
                        WHERE id = ?
                    """, (DataStatus.DELETED.value, datetime.now(timezone.utc).isoformat(), record_id))
                logger.info(f"Soft deleted record {record_id}")
            else:
                with sqlite3.connect(self.db_path) as conn:
                    conn.execute("DELETE FROM data_records WHERE id = ?", (record_id,))
                logger.info(f"Hard deleted record {record_id}")
            
            return True
    
    def create_backup(self, data_type: DataType) -> str:
        """Create backup for specific data type"""
        records = self.get_records_by_type(data_type)
        return self.backup_manager.create_backup(data_type, records)
    
    def restore_backup(self, backup_file: str) -> int:
        """Restore data from backup"""
        records = self.backup_manager.restore_backup(backup_file)
        
        with sqlite3.connect(self.db_path) as conn:
            for record in records:
                conn.execute("""
                    INSERT OR REPLACE INTO data_records 
                    (id, data_type, data, metadata, status, created_at, updated_at, version, checksum)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    record.id,
                    record.data_type.value,
                    json.dumps(record.data),
                    json.dumps(record.metadata),
                    record.status.value,
                    record.created_at.isoformat(),
                    record.updated_at.isoformat(),
                    record.version,
                    record.checksum
                ))
        
        logger.info(f"Restored {len(records)} records from backup")
        return len(records)
    
    def get_analytics(self) -> Dict[str, Any]:
        """Get comprehensive analytics"""
        return {
            'usage_statistics': self.analytics.get_usage_statistics(),
            'data_quality': self.analytics.get_data_quality_report()
        }

# Global database manager instance
db_manager = DatabaseManager()

def get_database_manager() -> DatabaseManager:
    """Get the global database manager instance"""
    return db_manager
