import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class EnhancedWeatherScreen extends StatefulWidget {
  const EnhancedWeatherScreen({super.key});

  @override
  State<EnhancedWeatherScreen> createState() => _EnhancedWeatherScreenState();
}

class _EnhancedWeatherScreenState extends State<EnhancedWeatherScreen>
    with TickerProviderStateMixin {
  String cityName = "Delhi";
  String weatherDescription = "";
  double? temperature;
  int? humidity;
  double? windSpeed;
  String? weatherIcon;
  bool isLoading = false;
  String errorMessage = "";

  final TextEditingController _cityController = TextEditingController();
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _cityController.text = cityName;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);

    // Fetch initial weather
    fetchWeather(cityName);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> fetchWeather(String city) async {
    // Validate API key configuration
    if (!AppConfig.isWeatherApiKeyValid) {
      setState(() {
        errorMessage =
            "Weather API key not configured. Please check environment variables.";
        isLoading = false;
      });
      return;
    }

    final apiKey = AppConfig.weatherApiKey;
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          cityName = data['name'];
          weatherDescription = data['weather'][0]['description'];
          temperature = data['main']['temp'];
          humidity = data['main']['humidity'];
          windSpeed = data['wind']['speed'];
          weatherIcon = data['weather'][0]['icon'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "City not found. Please try again.";
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage =
            "Error fetching weather data. Please check your connection.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchSection(),
                const SizedBox(height: 24),
                if (isLoading) _buildLoadingCard(),
                if (!isLoading && errorMessage.isNotEmpty) _buildErrorCard(),
                if (!isLoading &&
                    errorMessage.isEmpty &&
                    temperature != null) ...[
                  _buildWeatherCard(),
                  const SizedBox(height: 24),
                  _buildWeatherDetails(),
                  const SizedBox(height: 24),
                  _buildWeatherForecast(),
                ],
                const SizedBox(height: 100), // Space for bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF00BCD4),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Weather Forecast',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => fetchWeather(cityName),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00BCD4),
            Color(0xFF26C6DA),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BCD4).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Check Weather',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get real-time weather information for any city',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: 'Enter city name',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.location_city,
                        color: Colors.white.withOpacity(0.8)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: FloatingActionButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              final city = _cityController.text.trim();
                              if (city.isNotEmpty) {
                                fetchWeather(city);
                              }
                            },
                      backgroundColor: Colors.white,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00BCD4)),
                              ),
                            )
                          : const Icon(Icons.search, color: Color(0xFF00BCD4)),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
          ),
          const SizedBox(height: 16),
          Text(
            'Fetching weather data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getWeatherColor().withOpacity(0.1),
            _getWeatherColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getWeatherColor().withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cityName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _capitalizeFirst(weatherDescription),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (weatherIcon != null)
                Image.network(
                  'https://openweathermap.org/img/wn/$weatherIcon@2x.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    _getWeatherIcon(),
                    size: 80,
                    color: _getWeatherColor(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${temperature?.toStringAsFixed(1)}°',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'C',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildDetailCard(
            icon: Icons.water_drop,
            title: 'Humidity',
            value: '$humidity%',
            color: const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDetailCard(
            icon: Icons.air,
            title: 'Wind Speed',
            value: '${windSpeed?.toStringAsFixed(1)} m/s',
            color: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherForecast() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weather Tips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            icon: Icons.agriculture,
            title: 'Farming Advice',
            description: _getFarmingAdvice(),
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            icon: Icons.wb_sunny,
            title: 'Weather Alert',
            description: _getWeatherAlert(),
            color: const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getWeatherColor() {
    if (weatherDescription.contains('rain') ||
        weatherDescription.contains('storm')) {
      return const Color(0xFF2196F3);
    } else if (weatherDescription.contains('cloud')) {
      return const Color(0xFF9E9E9E);
    } else if (weatherDescription.contains('sun') ||
        weatherDescription.contains('clear')) {
      return const Color(0xFFFF9800);
    } else {
      return const Color(0xFF00BCD4);
    }
  }

  IconData _getWeatherIcon() {
    if (weatherDescription.contains('rain') ||
        weatherDescription.contains('storm')) {
      return Icons.thunderstorm;
    } else if (weatherDescription.contains('cloud')) {
      return Icons.cloud;
    } else if (weatherDescription.contains('sun') ||
        weatherDescription.contains('clear')) {
      return Icons.wb_sunny;
    } else {
      return Icons.wb_cloudy;
    }
  }

  String _getFarmingAdvice() {
    if (temperature != null) {
      if (temperature! < 10) {
        return 'Cold weather - protect crops from frost';
      } else if (temperature! > 35) {
        return 'Hot weather - ensure adequate irrigation';
      } else if (humidity != null && humidity! > 80) {
        return 'High humidity - watch for fungal diseases';
      } else {
        return 'Good weather conditions for farming';
      }
    }
    return 'Check weather conditions before farming activities';
  }

  String _getWeatherAlert() {
    if (weatherDescription.contains('storm') ||
        weatherDescription.contains('thunder')) {
      return 'Storm warning - avoid outdoor activities';
    } else if (weatherDescription.contains('rain')) {
      return 'Rain expected - plan irrigation accordingly';
    } else if (temperature != null && temperature! > 40) {
      return 'Extreme heat warning - take precautions';
    } else {
      return 'Normal weather conditions';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
