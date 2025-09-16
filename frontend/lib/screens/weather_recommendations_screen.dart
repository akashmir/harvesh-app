import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class WeatherRecommendationsScreen extends StatefulWidget {
  const WeatherRecommendationsScreen({super.key});

  @override
  State<WeatherRecommendationsScreen> createState() =>
      _WeatherRecommendationsScreenState();
}

class _WeatherRecommendationsScreenState
    extends State<WeatherRecommendationsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _recommendations;
  Map<String, dynamic>? _impactAnalysis;
  Map<String, dynamic>? _irrigationRecommendations;
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

    _loadWeatherRecommendations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherRecommendations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // First get current weather
      final weatherResponse = await NetworkService.get(
        '${AppConfig.weatherIntegrationApiBaseUrl}/weather/current?location=$_selectedLocation',
        timeout: const Duration(seconds: 30),
      );

      if (weatherResponse['success']) {
        setState(() {
          _currentWeather =
              Map<String, dynamic>.from(weatherResponse['data'] as Map);
        });

        // Then get recommendations based on weather
        final recommendationsResponse = await NetworkService.post(
          '${AppConfig.weatherIntegrationApiBaseUrl}/weather/recommendations',
          body: {'weather_data': _currentWeather},
          timeout: const Duration(seconds: 30),
        );

        if (recommendationsResponse['success']) {
          setState(() {
            final data = recommendationsResponse['data'];
            _recommendations =
                Map<String, dynamic>.from(data['recommendations'] as Map);
            _impactAnalysis =
                Map<String, dynamic>.from(data['impact_analysis'] as Map);
            _irrigationRecommendations = Map<String, dynamic>.from(
                data['irrigation_recommendations'] as Map);
            _isLoading = false;
          });
          _animationController.forward();
        } else {
          setState(() {
            _errorMessage = recommendationsResponse['error'] ??
                'Failed to load recommendations';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              weatherResponse['error'] ?? 'Failed to load weather data';
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
          'Weather Recommendations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF9800),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWeatherRecommendations,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingWidget(message: 'Loading weather recommendations...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: CustomErrorWidget(
          message: _errorMessage!,
          onRetry: _loadWeatherRecommendations,
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
              _buildWeatherSummary(),
              const SizedBox(height: 24),
              _buildCropRecommendations(),
              const SizedBox(height: 24),
              _buildImpactAnalysis(),
              const SizedBox(height: 24),
              _buildIrrigationRecommendations(),
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
        color: Color(0xFFFF9800),
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
                  Icons.lightbulb,
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
                      'Weather Recommendations',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-powered agricultural advice based on current weather',
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

  Widget _buildWeatherSummary() {
    if (_currentWeather == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Weather Summary',
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
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
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
                      color: const Color(0xFFFF9800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentWeather!['weather_condition'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9800),
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
                    const Color(0xFF4CAF50),
                  ),
                ),
                Expanded(
                  child: _buildWeatherDetail(
                    'Wind Speed',
                    '${_currentWeather!['wind_speed']?.toStringAsFixed(1) ?? '0'} km/h',
                    Icons.air,
                    const Color(0xFF2196F3),
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

  Widget _buildCropRecommendations() {
    if (_recommendations == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crop Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recommendations!['description'] ??
                        'No description available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Irrigation: ${_recommendations!['irrigation'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                  Text(
                    'Planting Time: ${_recommendations!['planting_time'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_recommendations!['crops'] != null &&
                (_recommendations!['crops'] as List).isNotEmpty) ...[
              const Text(
                'Recommended Crops:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_recommendations!['crops'] as List).map((crop) {
                  return Chip(
                    label: Text(
                      crop,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                    labelStyle: const TextStyle(color: Color(0xFF4CAF50)),
                  );
                }).toList(),
              ),
            ],
            if (_recommendations!['specific_recommendations'] != null &&
                (_recommendations!['specific_recommendations'] as List)
                    .isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Specific Recommendations:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              ...(_recommendations!['specific_recommendations'] as List)
                  .map((rec) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImpactAnalysis() {
    if (_impactAnalysis == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weather Impact Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            ..._impactAnalysis!.entries.map((entry) {
              final key = entry.key;
              final value = entry.value as Map<String, dynamic>;
              return _buildImpactItem(key, value);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactItem(String factor, Map<String, dynamic> data) {
    Color statusColor = _getStatusColor(data['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getFactorIcon(factor),
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                factor.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['status']?.toUpperCase() ?? 'UNKNOWN',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data['impact'] ?? 'No impact data',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['recommendation'] ?? 'No recommendation',
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIrrigationRecommendations() {
    if (_irrigationRecommendations == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Irrigation Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _irrigationRecommendations!['recommendation'] ??
                        'No recommendation',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildIrrigationDetail(
                          'Frequency',
                          _irrigationRecommendations!['frequency'] ?? 'Unknown',
                          Icons.schedule,
                          const Color(0xFF2196F3),
                        ),
                      ),
                      Expanded(
                        child: _buildIrrigationDetail(
                          'Amount',
                          _irrigationRecommendations!['amount'] ?? 'Unknown',
                          Icons.water_drop,
                          const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Environmental Factors:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildFactorDetail(
                    'Temperature',
                    '${_irrigationRecommendations!['factors']?['temperature']?.toStringAsFixed(1) ?? '0'}°C',
                    Icons.thermostat,
                    const Color(0xFFFF9800),
                  ),
                ),
                Expanded(
                  child: _buildFactorDetail(
                    'Humidity',
                    '${_irrigationRecommendations!['factors']?['humidity']?.toStringAsFixed(1) ?? '0'}%',
                    Icons.water_drop,
                    const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildFactorDetail(
                    'Precipitation',
                    '${_irrigationRecommendations!['factors']?['precipitation']?.toStringAsFixed(1) ?? '0'} mm',
                    Icons.grain,
                    const Color(0xFF2196F3),
                  ),
                ),
                Expanded(
                  child: _buildFactorDetail(
                    'Wind Speed',
                    '${_irrigationRecommendations!['factors']?['wind_speed']?.toStringAsFixed(1) ?? '0'} km/h',
                    Icons.air,
                    const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIrrigationDetail(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFactorDetail(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'optimal':
        return Colors.green;
      case 'too_high':
      case 'too_hot':
        return Colors.red;
      case 'too_low':
      case 'too_cold':
        return Colors.blue;
      case 'too_strong':
        return Colors.orange;
      case 'too_weak':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getFactorIcon(String factor) {
    switch (factor.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'wind':
        return Icons.air;
      case 'rainfall':
        return Icons.grain;
      default:
        return Icons.info;
    }
  }
}
