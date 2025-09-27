import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class WeatherAlertsScreen extends StatefulWidget {
  const WeatherAlertsScreen({super.key});

  @override
  State<WeatherAlertsScreen> createState() => _WeatherAlertsScreenState();
}

class _WeatherAlertsScreenState extends State<WeatherAlertsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedLocation = 'Delhi';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _loadWeatherAlerts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherAlerts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await NetworkService.get(
        '${AppConfig.weatherIntegrationApiBaseUrl}/weather/alerts?location=$_selectedLocation',
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          final alertsData = response['data']['alerts'] as List;
          _alerts = alertsData
              .map((alert) => Map<String, dynamic>.from(alert as Map))
              .toList();
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to load weather alerts';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Weather Alerts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF44336),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWeatherAlerts,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingWidget(message: 'Loading weather alerts...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: CustomErrorWidget(
          message: _errorMessage!,
          onRetry: _loadWeatherAlerts,
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildAlertControls(),
              const SizedBox(height: 24),
              _buildAlertsList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFF44336),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weather Alerts',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stay informed about weather conditions affecting agriculture',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildHeaderStat(
                Icons.location_on,
                _selectedLocation,
                'Location',
              ),
              const SizedBox(width: 24),
              _buildHeaderStat(
                Icons.warning,
                '${_alerts.length}',
                'Active Alerts',
              ),
              const SizedBox(width: 24),
              _buildHeaderStat(
                Icons.schedule,
                'Real-time',
                'Updates',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertControls() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon:
                          Icon(Icons.location_on, color: Color(0xFFF44336)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFF44336)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Delhi', child: Text('Delhi')),
                      DropdownMenuItem(value: 'Mumbai', child: Text('Mumbai')),
                      DropdownMenuItem(
                          value: 'Bangalore', child: Text('Bangalore')),
                      DropdownMenuItem(
                          value: 'Chennai', child: Text('Chennai')),
                      DropdownMenuItem(
                          value: 'Kolkata', child: Text('Kolkata')),
                      DropdownMenuItem(
                          value: 'Hyderabad', child: Text('Hyderabad')),
                      DropdownMenuItem(value: 'Pune', child: Text('Pune')),
                      DropdownMenuItem(
                          value: 'Ahmedabad', child: Text('Ahmedabad')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value!;
                      });
                      _loadWeatherAlerts();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadWeatherAlerts,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList() {
    if (_alerts.isEmpty) {
      return _buildEmptyAlerts();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Weather Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            ..._alerts.map((alert) => _buildAlertItem(alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAlerts() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Alerts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No weather alerts for your location at this time',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    Color alertColor = _getAlertColor(alert['severity']);
    IconData alertIcon = _getAlertIcon(alert['alert_type']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alertColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(alertIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['alert_type'] ?? 'Unknown Alert',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: alertColor,
                      ),
                    ),
                    Text(
                      'Severity: ${alert['severity'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: alertColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: alertColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  alert['severity']?.toUpperCase() ?? 'UNKNOWN',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert['message'] ?? 'No message available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Start: ${alert['start_date'] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.event,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'End: ${alert['end_date'] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getAgriculturalAdvice(alert),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'heat wave':
        return Icons.wb_sunny;
      case 'heavy rain':
        return Icons.grain;
      case 'frost warning':
        return Icons.ac_unit;
      case 'storm':
        return Icons.flash_on;
      case 'drought':
        return Icons.water_drop;
      case 'flood':
        return Icons.waves;
      default:
        return Icons.warning;
    }
  }

  String _getAgriculturalAdvice(Map<String, dynamic> alert) {
    final alertType = alert['alert_type']?.toLowerCase() ?? '';

    switch (alertType) {
      case 'heat wave':
        return 'Avoid field work during peak hours (10 AM - 4 PM). Increase irrigation frequency and use shade nets for sensitive crops.';
      case 'heavy rain':
        return 'Ensure proper drainage in fields. Avoid planting or harvesting during heavy rain. Check for waterlogging.';
      case 'frost warning':
        return 'Cover sensitive crops with frost cloth or plastic sheets. Water plants before frost to provide insulation.';
      case 'storm':
        return 'Avoid all field activities. Secure farm equipment and structures. Check for crop damage after storm passes.';
      case 'drought':
        return 'Implement water conservation measures. Consider drought-resistant crop varieties. Mulch soil to retain moisture.';
      case 'flood':
        return 'Move livestock to higher ground. Secure farm equipment. Avoid planting in low-lying areas.';
      default:
        return 'Monitor weather conditions closely and take appropriate precautions for your crops and livestock.';
    }
  }
}
