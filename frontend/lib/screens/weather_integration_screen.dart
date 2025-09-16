import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';
import '../services/weather_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'weather_forecast_screen.dart';
import 'weather_recommendations_screen.dart';
import 'weather_alerts_screen.dart';

class WeatherIntegrationScreen extends StatefulWidget {
  const WeatherIntegrationScreen({super.key});

  @override
  State<WeatherIntegrationScreen> createState() =>
      _WeatherIntegrationScreenState();
}

class _WeatherIntegrationScreenState extends State<WeatherIntegrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _forecasts = [];
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic> _analytics = {};
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

    _loadWeatherData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load current weather
      await _loadCurrentWeather();

      // Load weather forecast
      await _loadWeatherForecast();

      // Load weather alerts
      await _loadWeatherAlerts();

      // Load weather analytics
      await _loadWeatherAnalytics();

      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentWeather() async {
    try {
      final response =
          await WeatherService.getCurrentWeather(_selectedLocation);

      if (response['success']) {
        setState(() {
          _currentWeather = Map<String, dynamic>.from(response['data'] as Map);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadWeatherForecast() async {
    try {
      final response =
          await WeatherService.getWeatherForecast(_selectedLocation, days: 5);

      if (response['success']) {
        setState(() {
          final forecastsData = response['data']['forecasts'] as List;
          _forecasts = forecastsData
              .map((forecast) => Map<String, dynamic>.from(forecast as Map))
              .toList();
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadWeatherAlerts() async {
    try {
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
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadWeatherAnalytics() async {
    try {
      final response = await NetworkService.get(
        '${AppConfig.weatherIntegrationApiBaseUrl}/weather/analytics',
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          _analytics = Map<String, dynamic>.from(response['data'] as Map);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Weather Integration',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWeatherData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingWidget(message: 'Loading weather data...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: CustomErrorWidget(
          message: _errorMessage!,
          onRetry: _loadWeatherData,
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
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildCurrentWeather(),
              const SizedBox(height: 24),
              _buildWeatherForecast(),
              const SizedBox(height: 24),
              _buildWeatherAlerts(),
              const SizedBox(height: 24),
              _buildWeatherAnalytics(),
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
        color: Color(0xFF2196F3),
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
                  Icons.wb_sunny,
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
                      'Weather Intelligence',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time weather data & agricultural insights',
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
                Icons.thermostat,
                '${_currentWeather?['temperature']?.toStringAsFixed(0) ?? '0'}°C',
                'Temperature',
              ),
              const SizedBox(width: 24),
              _buildHeaderStat(
                Icons.water_drop,
                '${_currentWeather?['humidity']?.toStringAsFixed(0) ?? '0'}%',
                'Humidity',
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

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Weather Forecast',
            '5-day weather forecast',
            Icons.calendar_today,
            const Color(0xFF2196F3),
            () => _navigateToForecast(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            'Recommendations',
            'Weather-based crop advice',
            Icons.lightbulb,
            const Color(0xFFFF9800),
            () => _navigateToRecommendations(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeather() {
    if (_currentWeather == null) {
      return _buildEmptyWeather();
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
              'Current Weather',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_currentWeather!['temperature']?.toStringAsFixed(1) ?? '0'}°C',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      Text(
                        _currentWeather!['weather_description'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _currentWeather!['location'] ?? 'Unknown Location',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      _getWeatherIcon(_currentWeather!['weather_condition']),
                      size: 48,
                      color: const Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentWeather!['weather_condition'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherDetail(
                    'Humidity',
                    '${_currentWeather!['humidity']?.toStringAsFixed(0) ?? '0'}%',
                    Icons.water_drop,
                    const Color(0xFF2196F3),
                  ),
                ),
                Expanded(
                  child: _buildWeatherDetail(
                    'Wind Speed',
                    '${_currentWeather!['wind_speed']?.toStringAsFixed(1) ?? '0'} km/h',
                    Icons.air,
                    const Color(0xFF4CAF50),
                  ),
                ),
                Expanded(
                  child: _buildWeatherDetail(
                    'Pressure',
                    '${_currentWeather!['pressure']?.toStringAsFixed(0) ?? '0'} hPa',
                    Icons.speed,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWeather() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.wb_cloudy,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Weather Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load current weather data',
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

  Widget _buildWeatherDetail(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherForecast() {
    if (_forecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '5-Day Forecast',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToForecast(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._forecasts
                .take(3)
                .map((forecast) => _buildForecastItem(forecast)),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(Map<String, dynamic> forecast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getWeatherIcon(forecast['weather_condition']),
              color: const Color(0xFF2196F3),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  forecast['date'] ?? 'Unknown Date',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  forecast['weather_description'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${forecast['temperature_max']?.toStringAsFixed(0) ?? '0'}°/${forecast['temperature_min']?.toStringAsFixed(0) ?? '0'}°',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
              Text(
                '${forecast['humidity']?.toStringAsFixed(0) ?? '0'}% humidity',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlerts() {
    if (_alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weather Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToAlerts(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._alerts.take(2).map((alert) => _buildAlertItem(alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    Color alertColor = _getAlertColor(alert['severity']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getAlertIcon(alert['alert_type']),
            color: alertColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['alert_type'] ?? 'Unknown Alert',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: alertColor,
                  ),
                ),
                Text(
                  alert['message'] ?? 'No message',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            alert['severity'] ?? 'Unknown',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: alertColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAnalytics() {
    if (_analytics.isEmpty) {
      return const SizedBox.shrink();
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
              'Weather Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem(
                    'Avg Temperature',
                    '${_analytics['temperature_analytics']?['average']?.toStringAsFixed(1) ?? '0'}°C',
                    Icons.thermostat,
                    const Color(0xFF2196F3),
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Avg Humidity',
                    '${_analytics['humidity_analytics']?['average']?.toStringAsFixed(1) ?? '0'}%',
                    Icons.water_drop,
                    const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem(
                    'Min Temperature',
                    '${_analytics['temperature_analytics']?['minimum']?.toStringAsFixed(1) ?? '0'}°C',
                    Icons.thermostat_outlined,
                    const Color(0xFF2196F3),
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Max Temperature',
                    '${_analytics['temperature_analytics']?['maximum']?.toStringAsFixed(1) ?? '0'}°C',
                    Icons.thermostat_outlined,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.wb_cloudy;
      case 'rain':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.wb_cloudy;
    }
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
      default:
        return Icons.warning;
    }
  }

  void _navigateToForecast() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeatherForecastScreen(),
      ),
    );
  }

  void _navigateToRecommendations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeatherRecommendationsScreen(),
      ),
    );
  }

  void _navigateToAlerts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeatherAlertsScreen(),
      ),
    );
  }
}
