import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class WeatherForecastScreen extends StatefulWidget {
  const WeatherForecastScreen({super.key});

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _forecasts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedLocation = 'Delhi';
  int _selectedDays = 5;

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

    _loadForecast();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadForecast() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await NetworkService.get(
        '${AppConfig.weatherIntegrationApiBaseUrl}/weather/forecast?location=$_selectedLocation&days=$_selectedDays',
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          final forecastsData = response['data']['forecasts'] as List;
          _forecasts = forecastsData
              .map((forecast) => Map<String, dynamic>.from(forecast as Map))
              .toList();
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to load forecast';
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
          'Weather Forecast',
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
            onPressed: _loadForecast,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingWidget(message: 'Loading weather forecast...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: CustomErrorWidget(
          message: _errorMessage!,
          onRetry: _loadForecast,
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
              _buildForecastControls(),
              const SizedBox(height: 24),
              _buildForecastList(),
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
                  Icons.calendar_today,
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
                      'Weather Forecast',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Plan your agricultural activities with weather insights',
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
                Icons.calendar_view_week,
                '$_selectedDays days',
                'Forecast Period',
              ),
              const SizedBox(width: 24),
              _buildHeaderStat(
                Icons.wb_sunny,
                '${_forecasts.length}',
                'Forecasts',
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

  Widget _buildForecastControls() {
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
                          Icon(Icons.location_on, color: Color(0xFF2196F3)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2196F3)),
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
                      _loadForecast();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedDays,
                    decoration: const InputDecoration(
                      labelText: 'Days',
                      prefixIcon:
                          Icon(Icons.calendar_today, color: Color(0xFF2196F3)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2196F3)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('3 days')),
                      DropdownMenuItem(value: 5, child: Text('5 days')),
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                      DropdownMenuItem(value: 10, child: Text('10 days')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDays = value!;
                      });
                      _loadForecast();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastList() {
    if (_forecasts.isEmpty) {
      return _buildEmptyForecast();
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
              'Forecast Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            ..._forecasts.map((forecast) => _buildForecastItem(forecast)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyForecast() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Forecast Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load weather forecast data',
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

  Widget _buildForecastItem(Map<String, dynamic> forecast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getWeatherIcon(forecast['weather_condition']),
                  color: const Color(0xFF2196F3),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(forecast['date']),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      forecast['weather_description'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 14,
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
                    '${forecast['temperature_max']?.toStringAsFixed(0) ?? '0'}°',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  Text(
                    '${forecast['temperature_min']?.toStringAsFixed(0) ?? '0'}°',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildForecastDetail(
                  'Humidity',
                  '${forecast['humidity']?.toStringAsFixed(0) ?? '0'}%',
                  Icons.water_drop,
                  const Color(0xFF4CAF50),
                ),
              ),
              Expanded(
                child: _buildForecastDetail(
                  'Wind',
                  '${forecast['wind_speed']?.toStringAsFixed(1) ?? '0'} km/h',
                  Icons.air,
                  const Color(0xFF2196F3),
                ),
              ),
              Expanded(
                child: _buildForecastDetail(
                  'Rain',
                  '${forecast['precipitation']?.toStringAsFixed(1) ?? '0'} mm',
                  Icons.grain,
                  const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.green[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getAgriculturalAdvice(forecast),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
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

  Widget _buildForecastDetail(
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown Date';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Tomorrow';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
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

  String _getAgriculturalAdvice(Map<String, dynamic> forecast) {
    final temp = forecast['temperature_max'] ?? 0;
    final humidity = forecast['humidity'] ?? 0;
    final precipitation = forecast['precipitation'] ?? 0;
    final windSpeed = forecast['wind_speed'] ?? 0;

    if (temp > 35) {
      return 'High temperature: Avoid field work during peak hours, increase irrigation';
    } else if (temp < 10) {
      return 'Low temperature: Protect sensitive crops, consider covering';
    } else if (precipitation > 20) {
      return 'Heavy rain expected: Ensure proper drainage, avoid waterlogging';
    } else if (windSpeed > 15) {
      return 'Strong winds: Avoid field work, check for crop damage';
    } else if (humidity > 80) {
      return 'High humidity: Watch for fungal diseases, ensure ventilation';
    } else if (precipitation < 5 && temp > 25) {
      return 'Dry conditions: Increase irrigation, consider drought-resistant crops';
    } else {
      return 'Good weather conditions for agricultural activities';
    }
  }
}
