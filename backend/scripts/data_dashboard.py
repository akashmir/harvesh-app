"""
Data Management Dashboard
Real-time data analytics, quality monitoring, and management interface
"""

from flask import Flask, render_template_string, jsonify, request
import requests
import json
import time
from datetime import datetime, timezone, timedelta
import threading
import logging
from data_management_system import get_database_manager, DataType

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
API_BASE_URL = "http://localhost:8080"
DASHBOARD_PORT = 5002
db_manager = get_database_manager()

# Dashboard HTML template
DASHBOARD_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Crop Recommendation API - Data Management Dashboard</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 20px; }
        .stat-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat-card h3 { margin: 0 0 15px 0; color: #2c3e50; }
        .stat-value { font-size: 2em; font-weight: bold; color: #27ae60; margin-bottom: 10px; }
        .stat-label { color: #7f8c8d; font-size: 0.9em; }
        .chart-container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .data-table { background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); overflow: hidden; }
        .data-table table { width: 100%; border-collapse: collapse; }
        .data-table th, .data-table td { padding: 12px; text-align: left; border-bottom: 1px solid #eee; }
        .data-table th { background: #f8f9fa; font-weight: 600; color: #2c3e50; }
        .data-table tr:hover { background: #f8f9fa; }
        .status-indicator { display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 8px; }
        .status-healthy { background: #27ae60; }
        .status-warning { background: #f39c12; }
        .status-error { background: #e74c3c; }
        .btn { background: #3498db; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; margin: 5px; }
        .btn:hover { background: #2980b9; }
        .btn-success { background: #27ae60; }
        .btn-warning { background: #f39c12; }
        .btn-danger { background: #e74c3c; }
        .refresh-btn { background: #3498db; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }
        .refresh-btn:hover { background: #2980b9; }
        .timestamp { color: #7f8c8d; font-size: 0.9em; }
        .alert { padding: 15px; margin: 10px 0; border-radius: 4px; }
        .alert-info { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
        .alert-warning { background: #fff3cd; border: 1px solid #ffeaa7; color: #856404; }
        .alert-danger { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
    </style>
    <script>
        function refreshData() {
            location.reload();
        }
        
        function createBackup(dataType) {
            fetch('/api/backup', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({data_type: dataType})
            })
            .then(response => response.json())
            .then(data => {
                if (data.message) {
                    alert('Backup created successfully: ' + data.backup_file);
                } else {
                    alert('Error creating backup: ' + data.error);
                }
            })
            .catch(error => {
                alert('Error creating backup: ' + error);
            });
        }
        
        // Auto-refresh every 30 seconds
        setInterval(refreshData, 30000);
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Data Management Dashboard</h1>
            <p>Comprehensive data analytics, quality monitoring, and management</p>
            <button class="refresh-btn" onclick="refreshData()">Refresh</button>
        </div>
        
        <!-- Data Overview -->
        <div class="stats-grid">
            <div class="stat-card">
                <h3>📈 Data Overview</h3>
                <div class="stat-value">{{ data_overview.total_records }}</div>
                <div class="stat-label">Total Records</div>
                <div style="margin-top: 10px;">
                    <div><span class="status-indicator status-healthy"></span>Crop Recommendations: {{ data_overview.crop_recommendations }}</div>
                    <div><span class="status-indicator status-healthy"></span>API Requests: {{ data_overview.api_requests }}</div>
                    <div><span class="status-indicator status-healthy"></span>User Profiles: {{ data_overview.user_profiles }}</div>
                </div>
            </div>
            
            <div class="stat-card">
                <h3>🔍 Data Quality</h3>
                <div class="stat-value">{{ "%.1f"|format(data_quality.quality_score) }}%</div>
                <div class="stat-label">Quality Score</div>
                <div style="margin-top: 10px;">
                    <div>Validation Errors: {{ data_quality.validation_errors }}</div>
                    <div>Missing Checksums: {{ data_quality.missing_checksums }}</div>
                    <div>Duplicate Records: {{ data_quality.duplicate_records }}</div>
                </div>
            </div>
            
            <div class="stat-card">
                <h3>📊 Usage Statistics</h3>
                <div class="stat-value">{{ usage_stats.total_requests }}</div>
                <div class="stat-label">Total Requests (30 days)</div>
                <div style="margin-top: 10px;">
                    <div>Unique Users: {{ usage_stats.unique_users }}</div>
                    <div>Error Rate: {{ "%.2f"|format(usage_stats.error_rate * 100) }}%</div>
                    <div>Avg Response Time: {{ "%.3f"|format(usage_stats.avg_response_time) }}s</div>
                </div>
            </div>
            
            <div class="stat-card">
                <h3>🌱 Popular Crops</h3>
                <div style="font-size: 1.2em; font-weight: bold; color: #27ae60;">{{ popular_crops[0].crop if popular_crops else 'N/A' }}</div>
                <div class="stat-label">Most Recommended</div>
                <div style="margin-top: 10px;">
                    {% for crop in popular_crops[:5] %}
                    <div>{{ crop.crop }}: {{ crop.count }} times</div>
                    {% endfor %}
                </div>
            </div>
        </div>
        
        <!-- Data Management Actions -->
        <div class="chart-container">
            <h3>🛠️ Data Management Actions</h3>
            <div style="display: flex; flex-wrap: wrap; gap: 10px;">
                <button class="btn btn-success" onclick="createBackup('crop_recommendation')">Backup Crop Data</button>
                <button class="btn btn-success" onclick="createBackup('api_request')">Backup API Logs</button>
                <button class="btn btn-success" onclick="createBackup('user_profile')">Backup User Data</button>
                <button class="btn btn-warning" onclick="refreshData()">Refresh Analytics</button>
                <button class="btn" onclick="window.open('/api/analytics', '_blank')">View Raw Analytics</button>
            </div>
        </div>
        
        <!-- Recent Activity -->
        <div class="data-table">
            <h3 style="padding: 20px 20px 0 20px; margin: 0;">📋 Recent Activity</h3>
            <table>
                <thead>
                    <tr>
                        <th>Time</th>
                        <th>Type</th>
                        <th>Details</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    {% for activity in recent_activity %}
                    <tr>
                        <td>{{ activity.timestamp }}</td>
                        <td>{{ activity.type }}</td>
                        <td>{{ activity.details }}</td>
                        <td>
                            <span class="status-indicator status-{{ activity.status }}"></span>
                            {{ activity.status.title() }}
                        </td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
        
        <!-- Data Quality Alerts -->
        {% if data_quality.alerts %}
        <div style="margin-top: 20px;">
            <h3>⚠️ Data Quality Alerts</h3>
            {% for alert in data_quality.alerts %}
            <div class="alert alert-{{ alert.type }}">
                <strong>{{ alert.title }}:</strong> {{ alert.message }}
            </div>
            {% endfor %}
        </div>
        {% endif %}
        
        <!-- System Information -->
        <div class="chart-container">
            <h3>ℹ️ System Information</h3>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px;">
                <div>
                    <strong>Database Status:</strong><br>
                    <span class="status-indicator status-healthy"></span>Connected
                </div>
                <div>
                    <strong>Data Validation:</strong><br>
                    <span class="status-indicator status-healthy"></span>Enabled
                </div>
                <div>
                    <strong>Analytics:</strong><br>
                    <span class="status-indicator status-healthy"></span>Active
                </div>
                <div>
                    <strong>Last Updated:</strong><br>
                    <span class="timestamp">{{ last_update }}</span>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
"""

def get_dashboard_data():
    """Get comprehensive dashboard data"""
    try:
        # Get analytics from database
        analytics = db_manager.get_analytics()
        usage_stats = analytics['usage_statistics']
        data_quality = analytics['data_quality']
        
        # Calculate data overview
        data_overview = {
            'total_records': data_quality['total_records'],
            'crop_recommendations': data_quality['data_types'].get('crop_recommendation', 0),
            'api_requests': data_quality['data_types'].get('api_request', 0),
            'user_profiles': data_quality['data_types'].get('user_profile', 0)
        }
        
        # Calculate quality score
        total_records = data_quality['total_records']
        if total_records > 0:
            quality_score = 100 - (
                (data_quality['validation_errors'] + 
                 data_quality['missing_checksums'] + 
                 data_quality['duplicate_records']) / total_records * 100
            )
        else:
            quality_score = 100
        
        data_quality['quality_score'] = max(0, quality_score)
        
        # Get popular crops
        popular_crops = [
            {'crop': crop, 'count': count} 
            for crop, count in usage_stats.get('popular_crops', {}).items()
        ]
        popular_crops.sort(key=lambda x: x['count'], reverse=True)
        
        # Generate recent activity (mock data for now)
        recent_activity = [
            {
                'timestamp': datetime.now(timezone.utc).strftime('%H:%M:%S'),
                'type': 'Crop Recommendation',
                'details': 'Rice recommended with 90.6% confidence',
                'status': 'healthy'
            },
            {
                'timestamp': (datetime.now(timezone.utc) - timedelta(minutes=5)).strftime('%H:%M:%S'),
                'type': 'API Request',
                'details': 'Health check endpoint accessed',
                'status': 'healthy'
            },
            {
                'timestamp': (datetime.now(timezone.utc) - timedelta(minutes=10)).strftime('%H:%M:%S'),
                'type': 'Data Backup',
                'details': 'Crop recommendation data backed up',
                'status': 'healthy'
            }
        ]
        
        # Generate quality alerts
        alerts = []
        if data_quality['validation_errors'] > 0:
            alerts.append({
                'type': 'warning',
                'title': 'Validation Errors',
                'message': f"{data_quality['validation_errors']} records have validation errors"
            })
        
        if data_quality['duplicate_records'] > 0:
            alerts.append({
                'type': 'warning',
                'title': 'Duplicate Records',
                'message': f"{data_quality['duplicate_records']} duplicate records found"
            })
        
        if data_quality['missing_checksums'] > 0:
            alerts.append({
                'type': 'danger',
                'title': 'Data Integrity',
                'message': f"{data_quality['missing_checksums']} records missing checksums"
            })
        
        data_quality['alerts'] = alerts
        
        return {
            'data_overview': data_overview,
            'data_quality': data_quality,
            'usage_stats': usage_stats,
            'popular_crops': popular_crops,
            'recent_activity': recent_activity,
            'last_update': datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
        }
        
    except Exception as e:
        logger.error(f"Error getting dashboard data: {e}")
        return {
            'data_overview': {'total_records': 0, 'crop_recommendations': 0, 'api_requests': 0, 'user_profiles': 0},
            'data_quality': {'quality_score': 0, 'validation_errors': 0, 'missing_checksums': 0, 'duplicate_records': 0, 'alerts': []},
            'usage_stats': {'total_requests': 0, 'unique_users': 0, 'error_rate': 0, 'avg_response_time': 0},
            'popular_crops': [],
            'recent_activity': [],
            'last_update': datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
        }

@app.route('/')
def dashboard():
    """Main data management dashboard"""
    data = get_dashboard_data()
    return render_template_string(DASHBOARD_TEMPLATE, **data)

@app.route('/api/analytics')
def api_analytics():
    """API endpoint for raw analytics data"""
    try:
        analytics = db_manager.get_analytics()
        return jsonify({
            'analytics': analytics,
            'timestamp': datetime.now(timezone.utc).isoformat()
        })
    except Exception as e:
        logger.error(f"Error getting analytics: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/backup', methods=['POST'])
def api_backup():
    """API endpoint for creating backups"""
    try:
        data_type_str = request.json.get('data_type', 'crop_recommendation')
        
        try:
            data_type = DataType(data_type_str)
        except ValueError:
            return jsonify({'error': f'Invalid data type: {data_type_str}'}), 400
        
        backup_file = db_manager.create_backup(data_type)
        
        return jsonify({
            'message': 'Backup created successfully',
            'backup_file': backup_file,
            'data_type': data_type_str,
            'timestamp': datetime.now(timezone.utc).isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error creating backup: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/health')
def api_health():
    """Health check endpoint"""
    try:
        # Check database connection
        db_status = "healthy"
        try:
            db_manager.get_all_records()
        except Exception as e:
            db_status = f"error: {str(e)}"
        
        return jsonify({
            'dashboard_status': 'healthy',
            'database_status': db_status,
            'timestamp': datetime.now(timezone.utc).isoformat()
        })
    except Exception as e:
        return jsonify({
            'dashboard_status': 'error',
            'error': str(e),
            'timestamp': datetime.now(timezone.utc).isoformat()
        }), 500

if __name__ == '__main__':
    logger.info(f"Starting Data Management Dashboard on port {DASHBOARD_PORT}")
    app.run(host='0.0.0.0', port=DASHBOARD_PORT, debug=False)
