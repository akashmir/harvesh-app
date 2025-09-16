"""
Performance Optimization System
Handles caching, model optimization, and performance monitoring
"""

import time
import threading
import queue
import hashlib
import pickle
import json
import os
import logging
from datetime import datetime, timezone, timedelta
from typing import Dict, List, Optional, Any, Tuple
from functools import wraps
import psutil
import numpy as np
from dataclasses import dataclass
from enum import Enum
import joblib
from concurrent.futures import ThreadPoolExecutor
import asyncio
import weakref

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CacheStrategy(Enum):
    LRU = "lru"  # Least Recently Used
    TTL = "ttl"  # Time To Live
    SIZE = "size"  # Size-based eviction

@dataclass
class CacheEntry:
    key: str
    value: Any
    created_at: datetime
    last_accessed: datetime
    access_count: int
    size_bytes: int
    ttl_seconds: Optional[int] = None

class OptimizedCache:
    """High-performance caching system with multiple strategies"""
    
    def __init__(self, max_size_mb: int = 100, default_ttl: int = 3600):
        self.max_size_bytes = max_size_mb * 1024 * 1024
        self.default_ttl = default_ttl
        self.cache: Dict[str, CacheEntry] = {}
        self.access_order = []
        self.current_size = 0
        self.lock = threading.RLock()
        self.hit_count = 0
        self.miss_count = 0
        
    def _calculate_size(self, obj: Any) -> int:
        """Calculate approximate size of object in bytes"""
        try:
            return len(pickle.dumps(obj))
        except:
            return 1024  # Default size if can't calculate
    
    def _is_expired(self, entry: CacheEntry) -> bool:
        """Check if cache entry is expired"""
        if entry.ttl_seconds is None:
            return False
        return (datetime.now(timezone.utc) - entry.created_at).total_seconds() > entry.ttl_seconds
    
    def _evict_lru(self):
        """Evict least recently used entries"""
        while self.current_size > self.max_size_bytes and self.access_order:
            key = self.access_order.pop(0)
            if key in self.cache:
                entry = self.cache[key]
                self.current_size -= entry.size_bytes
                del self.cache[key]
                logger.debug(f"Evicted LRU entry: {key}")
    
    def _evict_expired(self):
        """Remove expired entries"""
        expired_keys = []
        for key, entry in self.cache.items():
            if self._is_expired(entry):
                expired_keys.append(key)
        
        for key in expired_keys:
            entry = self.cache[key]
            self.current_size -= entry.size_bytes
            del self.cache[key]
            if key in self.access_order:
                self.access_order.remove(key)
            logger.debug(f"Evicted expired entry: {key}")
    
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        with self.lock:
            if key not in self.cache:
                self.miss_count += 1
                return None
            
            entry = self.cache[key]
            
            # Check if expired
            if self._is_expired(entry):
                self.current_size -= entry.size_bytes
                del self.cache[key]
                if key in self.access_order:
                    self.access_order.remove(key)
                self.miss_count += 1
                return None
            
            # Update access info
            entry.last_accessed = datetime.now(timezone.utc)
            entry.access_count += 1
            
            # Move to end of access order
            if key in self.access_order:
                self.access_order.remove(key)
            self.access_order.append(key)
            
            self.hit_count += 1
            return entry.value
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """Set value in cache"""
        with self.lock:
            # Remove existing entry if present
            if key in self.cache:
                old_entry = self.cache[key]
                self.current_size -= old_entry.size_bytes
                if key in self.access_order:
                    self.access_order.remove(key)
            
            # Calculate size
            size_bytes = self._calculate_size(value)
            
            # Create new entry
            entry = CacheEntry(
                key=key,
                value=value,
                created_at=datetime.now(timezone.utc),
                last_accessed=datetime.now(timezone.utc),
                access_count=1,
                size_bytes=size_bytes,
                ttl_seconds=ttl or self.default_ttl
            )
            
            # Check if we need to evict
            while (self.current_size + size_bytes > self.max_size_bytes and 
                   self.access_order):
                self._evict_lru()
            
            # Add new entry
            self.cache[key] = entry
            self.current_size += size_bytes
            self.access_order.append(key)
            
            logger.debug(f"Cached entry: {key} ({size_bytes} bytes)")
    
    def delete(self, key: str) -> bool:
        """Delete entry from cache"""
        with self.lock:
            if key not in self.cache:
                return False
            
            entry = self.cache[key]
            self.current_size -= entry.size_bytes
            del self.cache[key]
            if key in self.access_order:
                self.access_order.remove(key)
            
            logger.debug(f"Deleted cache entry: {key}")
            return True
    
    def clear(self) -> None:
        """Clear all cache entries"""
        with self.lock:
            self.cache.clear()
            self.access_order.clear()
            self.current_size = 0
            logger.info("Cache cleared")
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        with self.lock:
            total_requests = self.hit_count + self.miss_count
            hit_rate = self.hit_count / total_requests if total_requests > 0 else 0
            
            return {
                'size_bytes': self.current_size,
                'size_mb': self.current_size / (1024 * 1024),
                'max_size_mb': self.max_size_bytes / (1024 * 1024),
                'entry_count': len(self.cache),
                'hit_count': self.hit_count,
                'miss_count': self.miss_count,
                'hit_rate': hit_rate,
                'utilization': self.current_size / self.max_size_bytes
            }
    
    def cleanup_expired(self) -> int:
        """Clean up expired entries and return count removed"""
        with self.lock:
            before_count = len(self.cache)
            self._evict_expired()
            after_count = len(self.cache)
            removed = before_count - after_count
            if removed > 0:
                logger.info(f"Cleaned up {removed} expired cache entries")
            return removed

class ModelOptimizer:
    """Optimizes model loading and inference"""
    
    def __init__(self):
        self.models_cache = {}
        self.model_loading_lock = threading.Lock()
        self.model_loading_status = {}
        self.preloaded_models = {}
        
    def preload_models(self, model_paths: Dict[str, str]) -> bool:
        """Preload models in background thread"""
        def load_models_async():
            try:
                logger.info("Starting background model preloading...")
                
                # Load Random Forest model
                if 'rf' in model_paths:
                    self.preloaded_models['rf'] = joblib.load(model_paths['rf'])
                    logger.info("Random Forest model preloaded")
                
                # Load Scaler
                if 'scaler' in model_paths:
                    self.preloaded_models['scaler'] = joblib.load(model_paths['scaler'])
                    logger.info("Scaler preloaded")
                
                # Load Label Encoder
                if 'label_encoder' in model_paths:
                    self.preloaded_models['label_encoder'] = joblib.load(model_paths['label_encoder'])
                    logger.info("Label encoder preloaded")
                
                # Load Neural Network model
                if 'nn' in model_paths:
                    try:
                        from tensorflow.keras.models import load_model
                        self.preloaded_models['nn'] = load_model(model_paths['nn'])
                        logger.info("Neural Network model preloaded")
                    except Exception as e:
                        logger.warning(f"Failed to preload NN model: {e}")
                
                logger.info("All models preloaded successfully")
                return True
                
            except Exception as e:
                logger.error(f"Error preloading models: {e}")
                return False
        
        # Start background loading
        thread = threading.Thread(target=load_models_async, daemon=True)
        thread.start()
        return True
    
    def get_model(self, model_name: str) -> Optional[Any]:
        """Get preloaded model"""
        return self.preloaded_models.get(model_name)
    
    def is_model_ready(self, model_name: str) -> bool:
        """Check if model is ready"""
        return model_name in self.preloaded_models
    
    def get_loading_status(self) -> Dict[str, bool]:
        """Get model loading status"""
        return {name: name in self.preloaded_models for name in ['rf', 'scaler', 'label_encoder', 'nn']}

class PerformanceMonitor:
    """Advanced performance monitoring and optimization"""
    
    def __init__(self):
        self.metrics = {
            'response_times': [],
            'memory_usage': [],
            'cpu_usage': [],
            'cache_hits': 0,
            'cache_misses': 0,
            'db_queries': 0,
            'model_inferences': 0
        }
        self.alert_thresholds = {
            'response_time_ms': 1000,
            'memory_percent': 80,
            'cpu_percent': 80,
            'error_rate': 0.05
        }
        self.alerts = []
        self.lock = threading.Lock()
        
    def record_metric(self, metric_name: str, value: float):
        """Record a performance metric"""
        with self.lock:
            if metric_name in self.metrics:
                if isinstance(self.metrics[metric_name], list):
                    self.metrics[metric_name].append(value)
                    # Keep only last 1000 measurements
                    if len(self.metrics[metric_name]) > 1000:
                        self.metrics[metric_name] = self.metrics[metric_name][-1000:]
                else:
                    self.metrics[metric_name] += value
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get current performance metrics"""
        with self.lock:
            metrics = {}
            
            # Response times
            if self.metrics['response_times']:
                metrics['avg_response_time'] = sum(self.metrics['response_times']) / len(self.metrics['response_times'])
                metrics['max_response_time'] = max(self.metrics['response_times'])
                metrics['min_response_time'] = min(self.metrics['response_times'])
            else:
                metrics['avg_response_time'] = 0
                metrics['max_response_time'] = 0
                metrics['min_response_time'] = 0
            
            # Memory usage
            if self.metrics['memory_usage']:
                metrics['avg_memory_usage'] = sum(self.metrics['memory_usage']) / len(self.metrics['memory_usage'])
                metrics['max_memory_usage'] = max(self.metrics['memory_usage'])
            else:
                metrics['avg_memory_usage'] = 0
                metrics['max_memory_usage'] = 0
            
            # CPU usage
            if self.metrics['cpu_usage']:
                metrics['avg_cpu_usage'] = sum(self.metrics['cpu_usage']) / len(self.metrics['cpu_usage'])
                metrics['max_cpu_usage'] = max(self.metrics['cpu_usage'])
            else:
                metrics['avg_cpu_usage'] = 0
                metrics['max_cpu_usage'] = 0
            
            # Cache performance
            total_cache_requests = self.metrics['cache_hits'] + self.metrics['cache_misses']
            metrics['cache_hit_rate'] = self.metrics['cache_hits'] / total_cache_requests if total_cache_requests > 0 else 0
            metrics['cache_hits'] = self.metrics['cache_hits']
            metrics['cache_misses'] = self.metrics['cache_misses']
            
            # Other metrics
            metrics['db_queries'] = self.metrics['db_queries']
            metrics['model_inferences'] = self.metrics['model_inferences']
            
            return metrics
    
    def check_alerts(self) -> List[Dict[str, Any]]:
        """Check for performance alerts"""
        alerts = []
        metrics = self.get_metrics()
        
        # Response time alert
        if metrics['avg_response_time'] > self.alert_thresholds['response_time_ms']:
            alerts.append({
                'type': 'warning',
                'message': f"High response time: {metrics['avg_response_time']:.2f}ms",
                'threshold': self.alert_thresholds['response_time_ms']
            })
        
        # Memory usage alert
        if metrics['avg_memory_usage'] > self.alert_thresholds['memory_percent']:
            alerts.append({
                'type': 'critical',
                'message': f"High memory usage: {metrics['avg_memory_usage']:.1f}%",
                'threshold': self.alert_thresholds['memory_percent']
            })
        
        # CPU usage alert
        if metrics['avg_cpu_usage'] > self.alert_thresholds['cpu_percent']:
            alerts.append({
                'type': 'warning',
                'message': f"High CPU usage: {metrics['avg_cpu_usage']:.1f}%",
                'threshold': self.alert_thresholds['cpu_percent']
            })
        
        return alerts

class DatabaseOptimizer:
    """Optimizes database operations"""
    
    def __init__(self, db_manager):
        self.db_manager = db_manager
        self.query_cache = OptimizedCache(max_size_mb=50, default_ttl=300)  # 5 min TTL
        self.batch_queue = queue.Queue(maxsize=1000)
        self.batch_size = 10
        self.batch_timeout = 5  # seconds
        self.batch_thread = None
        self.start_batch_processor()
    
    def start_batch_processor(self):
        """Start background batch processor"""
        def process_batches():
            batch = []
            last_process = time.time()
            
            while True:
                try:
                    # Try to get item with timeout
                    item = self.batch_queue.get(timeout=1)
                    batch.append(item)
                    
                    # Process batch if size reached or timeout
                    current_time = time.time()
                    if (len(batch) >= self.batch_size or 
                        current_time - last_process > self.batch_timeout):
                        self._process_batch(batch)
                        batch = []
                        last_process = current_time
                        
                except queue.Empty:
                    # Process any remaining items
                    if batch:
                        self._process_batch(batch)
                        batch = []
                        last_process = time.time()
                except Exception as e:
                    logger.error(f"Error in batch processor: {e}")
        
        self.batch_thread = threading.Thread(target=process_batches, daemon=True)
        self.batch_thread.start()
    
    def _process_batch(self, batch: List[Dict[str, Any]]):
        """Process a batch of database operations"""
        try:
            for item in batch:
                operation = item.get('operation')
                if operation == 'save_record':
                    self.db_manager.save_record(
                        item['data_type'],
                        item['data'],
                        item.get('metadata', {})
                    )
                elif operation == 'update_record':
                    self.db_manager.update_record(
                        item['record_id'],
                        item['data'],
                        item.get('metadata', {})
                    )
            
            logger.debug(f"Processed batch of {len(batch)} operations")
        except Exception as e:
            logger.error(f"Error processing batch: {e}")
    
    def save_record_async(self, data_type, data: Dict[str, Any], metadata: Dict[str, Any] = None):
        """Save record asynchronously"""
        try:
            self.batch_queue.put({
                'operation': 'save_record',
                'data_type': data_type,
                'data': data,
                'metadata': metadata or {}
            }, timeout=1)
        except queue.Full:
            logger.warning("Batch queue full, dropping record")
    
    def get_cached_query(self, query_key: str, query_func, *args, **kwargs):
        """Get cached query result or execute and cache"""
        # Check cache first
        cached_result = self.query_cache.get(query_key)
        if cached_result is not None:
            return cached_result
        
        # Execute query
        result = query_func(*args, **kwargs)
        
        # Cache result
        self.query_cache.set(query_key, result)
        
        return result

# Global instances
cache = OptimizedCache(max_size_mb=100, default_ttl=3600)
model_optimizer = ModelOptimizer()
performance_monitor = PerformanceMonitor()

def get_cache() -> OptimizedCache:
    """Get global cache instance"""
    return cache

def get_model_optimizer() -> ModelOptimizer:
    """Get global model optimizer instance"""
    return model_optimizer

def get_performance_monitor() -> PerformanceMonitor:
    """Get global performance monitor instance"""
    return performance_monitor

def performance_timer(func):
    """Decorator to time function execution"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = func(*args, **kwargs)
            return result
        finally:
            execution_time = (time.time() - start_time) * 1000  # Convert to ms
            performance_monitor.record_metric('response_times', execution_time)
            
            # Record system metrics
            memory_percent = psutil.virtual_memory().percent
            cpu_percent = psutil.cpu_percent()
            performance_monitor.record_metric('memory_usage', memory_percent)
            performance_monitor.record_metric('cpu_usage', cpu_percent)
    
    return wrapper

def cache_result(ttl: int = 3600, key_func=None):
    """Decorator to cache function results"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key
            if key_func:
                cache_key = key_func(*args, **kwargs)
            else:
                cache_key = f"{func.__name__}:{hashlib.md5(str(args).encode() + str(kwargs).encode()).hexdigest()}"
            
            # Try to get from cache
            cached_result = cache.get(cache_key)
            if cached_result is not None:
                performance_monitor.record_metric('cache_hits', 1)
                return cached_result
            
            # Execute function and cache result
            result = func(*args, **kwargs)
            cache.set(cache_key, result, ttl=ttl)
            performance_monitor.record_metric('cache_misses', 1)
            
            return result
        return wrapper
    return decorator

def background_cleanup():
    """Background cleanup task"""
    while True:
        try:
            time.sleep(300)  # Run every 5 minutes
            cache.cleanup_expired()
            logger.debug("Background cleanup completed")
        except Exception as e:
            logger.error(f"Error in background cleanup: {e}")

# Start background cleanup
cleanup_thread = threading.Thread(target=background_cleanup, daemon=True)
cleanup_thread.start()
