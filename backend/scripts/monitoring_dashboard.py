"""
Production Monitoring Dashboard
Real-time monitoring and alerting for the Crop Recommendation API
"""

from flask import Flask, render_template_string, jsonify
import requests
import json
import time
from datetime import datetime, timezone
import threading
import queue
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
API_BASE_URL = "http://localhost:8080"
DASHBOARD_PORT = 5001
ALERT_THRESHOLDS = {
    'error_rate': 0.05,  # 5%
    'response_time': 2.0,  # 2 seconds
    'memory_usage': 80.0,  # 80%
    'cpu_usage': 80.0  # 80%
}

# Monitoring data
monitoring_data = {
    'last_update': None,
    'api_status': 'unknown',
    'metrics': {},
    'alerts': [],
    'uptime': 0
}

def check_api_health():
    """Check API health and collect metrics"""
    try:
        # Health check
        health_response = requests.get(f"{API_BASE_URL}/health", timeout=5)
        if health_response.status_code == 200:
            monitoring_data['api_status'] = 'healthy'
            monitoring_data['metrics'] = health_response.json()
        else:
            monitoring_data['api_status'] = 'unhealthy'
            
        # Detailed metrics
        try:
            metrics_response = requests.get(f"{API_BASE_URL}/metrics", timeout=5)
            if metrics_response.status_code == 200:
                monitoring_data['metrics'].update(metrics_response.json())
        except:
            pass
            
        monitoring_data['last_update'] = datetime.now(timezone.utc).isoformat()
        
        # Check for alerts
        check_alerts()
        
    except Exception as e:
        logger.error(f"Error checking API health: {e}")
        monitoring_data['api_status'] = 'error'
        monitoring_data['alerts'].append({
            'type': 'error',
            'message': f'API health check failed: {str(e)}',
            'timestamp': datetime.now(timezone.utc).isoformat()
        })

def check_alerts():
    """Check for alert conditions"""
    alerts = []
    metrics = monitoring_data.get('metrics', {})
    
    # Check error rate
    error_rate = metrics.get('performance', {}).get('error_rate', 0)
    if error_rate > ALERT_THRESHOLDS['error_rate']:
        alerts.append({
            'type': 'warning',
            'message': f'High error rate: {error_rate:.2%}',
            'timestamp': datetime.now(timezone.utc).isoformat()
        })
    
    # Check response time
    avg_response_time = metrics.get('performance', {}).get('avg_response_time', 0)
    if avg_response_time > ALERT_THRESHOLDS['response_time']:
        alerts.append({
            'type': 'warning',
            'message': f'High response time: {avg_response_time:.2f}s',
            'timestamp': datetime.now(timezone.utc).isoformat()
        })
    
    # Check memory usage
    memory_percent = metrics.get('system', {}).get('memory', {}).get('percent', 0)
    if memory_percent > ALERT_THRESHOLDS['memory_usage']:
        alerts.append({
            'type': 'critical',
            'message': f'High memory usage: {memory_percent:.1f}%',
            'timestamp': datetime.now(timezone.utc).isoformat()
        })
    
    # Check CPU usage
    cpu_percent = metrics.get('system', {}).get('cpu', {}).get('percent', 0)
    if cpu_percent > ALERT_THRESHOLDS['cpu_usage']:
        alerts.append({
            'type': 'critical',
            'message': f'High CPU usage: {cpu_percent:.1f}%',
            'timestamp': datetime.now(timezone.utc).isoformat()
        })
    
    # Add new alerts
    for alert in alerts:
        if alert not in monitoring_data['alerts']:
            monitoring_data['alerts'].append(alert)
    
    # Keep only last 50 alerts
    monitoring_data['alerts'] = monitoring_data['alerts'][-50:]

def background_monitoring():
    """Background monitoring thread"""
    while True:
        try:
            check_api_health()
            time.sleep(10)  # Check every 10 seconds
        except Exception as e:
            logger.error(f"Error in background monitoring: {e}")
            time.sleep(30)

# Dashboard HTML template
DASHBOARD_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Crop Recommendation API - Monitoring Dashboard</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .status-card { background: white; padding: 20px; margin: 10px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status-healthy { border-left: 4px solid #27ae60; }
        .status-unhealthy { border-left: 4px solid #e74c3c; }
        .status-error { border-left: 4px solid #f39c12; }
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .metric-value { font-size: 2em; font-weight: bold; color: #2c3e50; }
        .metric-label { color: #7f8c8d; margin-bottom: 10px; }
        .alert { padding: 10px; margin: 5px 0; border-radius: 4px; }
        .alert-warning { background: #fff3cd; border: 1px solid #ffeaa7; color: #856404; }
        .alert-critical { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
        .alert-error { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
        .refresh-btn { background: #3498db; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }
        .refresh-btn:hover { background: #2980b9; }
        .timestamp { color: #7f8c8d; font-size: 0.9em; }
    </style>
    <script>
        function refreshData() {
            location.reload();
        }
        
        // Auto-refresh every 30 seconds
        setInterval(refreshData, 30000);
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌱 Crop Recommendation API - Monitoring Dashboard</h1>
            <p>Real-time monitoring and performance metrics</p>
            <button class="refresh-btn" onclick="refreshData()">Refresh</button>
        </div>
        
        <div class="metrics-grid">
            <!-- API Status -->
            <div class="status-card status-{{ api_status }}">
                <div class="metric-label">API Status</div>
                <div class="metric-value">{{ api_status.upper() }}</div>
                <div class="timestamp">Last updated: {{ last_update }}</div>
            </div>
            
            <!-- Request Count -->
            <div class="status-card">
                <div class="metric-label">Total Requests</div>
                <div class="metric-value">{{ metrics.performance.request_count if metrics.performance else 0 }}</div>
            </div>
            
            <!-- Error Rate -->
            <div class="status-card">
                <div class="metric-label">Error Rate</div>
                <div class="metric-value">{{ "%.2f"|format(metrics.performance.error_rate * 100) if metrics.performance else 0 }}%</div>
            </div>
            
            <!-- Response Time -->
            <div class="status-card">
                <div class="metric-label">Avg Response Time</div>
                <div class="metric-value">{{ "%.3f"|format(metrics.performance.avg_response_time) if metrics.performance else 0 }}s</div>
            </div>
            
            <!-- Memory Usage -->
            <div class="status-card">
                <div class="metric-label">Memory Usage</div>
                <div class="metric-value">{{ "%.1f"|format(metrics.system.memory.percent) if metrics.system and metrics.system.memory else 0 }}%</div>
            </div>
            
            <!-- CPU Usage -->
            <div class="status-card">
                <div class="metric-label">CPU Usage</div>
                <div class="metric-value">{{ "%.1f"|format(metrics.system.cpu.percent) if metrics.system and metrics.system.cpu else 0 }}%</div>
            </div>
            
            <!-- Models Status -->
            <div class="status-card">
                <div class="metric-label">Models Loaded</div>
                <div class="metric-value">{{ "YES" if metrics.models and metrics.models.loaded else "NO" }}</div>
            </div>
            
            <!-- Uptime -->
            <div class="status-card">
                <div class="metric-label">Uptime</div>
                <div class="metric-value">{{ "%.0f"|format(metrics.performance.uptime_seconds / 3600) if metrics.performance else 0 }}h</div>
            </div>
        </div>
        
        <!-- Alerts -->
        {% if alerts %}
        <div class="status-card">
            <h3>🚨 Alerts</h3>
            {% for alert in alerts[-10:] %}
            <div class="alert alert-{{ alert.type }}">
                <strong>{{ alert.type.upper() }}:</strong> {{ alert.message }}
                <div class="timestamp">{{ alert.timestamp }}</div>
            </div>
            {% endfor %}
        </div>
        {% endif %}
        
        <!-- System Details -->
        <div class="status-card">
            <h3>📊 System Details</h3>
            <div class="metrics-grid">
                <div>
                    <strong>Memory:</strong><br>
                    Total: {{ "%.1f"|format(metrics.system.memory.total / 1024 / 1024 / 1024) if metrics.system and metrics.system.memory else 0 }} GB<br>
                    Available: {{ "%.1f"|format(metrics.system.memory.available / 1024 / 1024 / 1024) if metrics.system and metrics.system.memory else 0 }} GB
                </div>
                <div>
                    <strong>CPU:</strong><br>
                    Cores: {{ metrics.system.cpu.count if metrics.system and metrics.system.cpu else 0 }}<br>
                    Usage: {{ "%.1f"|format(metrics.system.cpu.percent) if metrics.system and metrics.system.cpu else 0 }}%
                </div>
                <div>
                    <strong>Disk:</strong><br>
                    Total: {{ "%.1f"|format(metrics.system.disk.total / 1024 / 1024 / 1024) if metrics.system and metrics.system.disk else 0 }} GB<br>
                    Used: {{ "%.1f"|format(metrics.system.disk.percent) if metrics.system and metrics.system.disk else 0 }}%
                </div>
            </div>
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def dashboard():
    """Main monitoring dashboard"""
    return render_template_string(DASHBOARD_TEMPLATE, 
                                api_status=monitoring_data['api_status'],
                                metrics=monitoring_data['metrics'],
                                alerts=monitoring_data['alerts'],
                                last_update=monitoring_data['last_update'])

@app.route('/api/status')
def api_status():
    """API status endpoint"""
    return jsonify(monitoring_data)

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=5)
        return jsonify({
            'dashboard_status': 'healthy',
            'api_status': 'healthy' if response.status_code == 200 else 'unhealthy',
            'timestamp': datetime.now(timezone.utc).isoformat()
        })
    except Exception as e:
        return jsonify({
            'dashboard_status': 'healthy',
            'api_status': 'error',
            'error': str(e),
            'timestamp': datetime.now(timezone.utc).isoformat()
        }), 500

if __name__ == '__main__':
    # Start background monitoring
    monitor_thread = threading.Thread(target=background_monitoring, daemon=True)
    monitor_thread.start()
    
    logger.info(f"Starting monitoring dashboard on port {DASHBOARD_PORT}")
    app.run(host='0.0.0.0', port=DASHBOARD_PORT, debug=False)
