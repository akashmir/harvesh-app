import 'dart:convert';
import 'package:http/http.dart' as http;

class RegionalData {
  final double latitude;
  final double longitude;
  final String region;
  final String country;
  final double temperature;
  final double humidity;
  final double rainfall;
  final double ph;
  final double nitrogen;
  final double phosphorus;
  final double potassium;

  RegionalData({
    required this.latitude,
    required this.longitude,
    required this.region,
    required this.country,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.ph,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'region': region,
      'country': country,
      'temperature': temperature,
      'humidity': humidity,
      'rainfall': rainfall,
      'ph': ph,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
    };
  }
}

class RegionalDataService {
  // Predefined regional data for different climate zones
  static final Map<String, RegionalData> _regionalData = {
    'tropical': RegionalData(
      latitude: 0.0,
      longitude: 0.0,
      region: 'Tropical',
      country: 'Tropical Region',
      temperature: 28.0,
      humidity: 85.0,
      rainfall: 250.0,
      ph: 6.2,
      nitrogen: 75.0,
      phosphorus: 45.0,
      potassium: 50.0,
    ),
    'temperate': RegionalData(
      latitude: 0.0,
      longitude: 0.0,
      region: 'Temperate',
      country: 'Temperate Region',
      temperature: 15.0,
      humidity: 70.0,
      rainfall: 120.0,
      ph: 6.8,
      nitrogen: 85.0,
      phosphorus: 55.0,
      potassium: 60.0,
    ),
    'arid': RegionalData(
      latitude: 0.0,
      longitude: 0.0,
      region: 'Arid',
      country: 'Arid Region',
      temperature: 35.0,
      humidity: 30.0,
      rainfall: 50.0,
      ph: 7.5,
      nitrogen: 40.0,
      phosphorus: 25.0,
      potassium: 35.0,
    ),
    'continental': RegionalData(
      latitude: 0.0,
      longitude: 0.0,
      region: 'Continental',
      country: 'Continental Region',
      temperature: 10.0,
      humidity: 60.0,
      rainfall: 80.0,
      ph: 6.5,
      nitrogen: 70.0,
      phosphorus: 40.0,
      potassium: 45.0,
    ),
  };

  static Future<RegionalData> getRegionalData(
      double latitude, double longitude) async {
    try {
      // First try to get real weather data from OpenWeatherMap API
      final weatherData = await _getWeatherData(latitude, longitude);
      if (weatherData != null) {
        return RegionalData(
          latitude: latitude,
          longitude: longitude,
          region: _getClimateZone(latitude, longitude),
          country: 'Detected Location',
          temperature:
              weatherData['temperature'] ?? _getDefaultTemperature(latitude),
          humidity: weatherData['humidity'] ?? _getDefaultHumidity(latitude),
          rainfall: weatherData['rainfall'] ?? _getDefaultRainfall(latitude),
          ph: _getDefaultPH(latitude),
          nitrogen: _getDefaultNitrogen(latitude),
          phosphorus: _getDefaultPhosphorus(latitude),
          potassium: _getDefaultPotassium(latitude),
        );
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }

    // Fallback to predefined data based on climate zone
    final climateZone = _getClimateZone(latitude, longitude);
    final baseData = _regionalData[climateZone] ?? _regionalData['temperate']!;

    return RegionalData(
      latitude: latitude,
      longitude: longitude,
      region: climateZone,
      country: 'Regional Data',
      temperature: baseData.temperature + _getLatitudeAdjustment(latitude),
      humidity: baseData.humidity + _getHumidityAdjustment(latitude),
      rainfall: baseData.rainfall + _getRainfallAdjustment(latitude),
      ph: baseData.ph + _getPHAdjustment(latitude),
      nitrogen: baseData.nitrogen + _getNitrogenAdjustment(latitude),
      phosphorus: baseData.phosphorus + _getPhosphorusAdjustment(latitude),
      potassium: baseData.potassium + _getPotassiumAdjustment(latitude),
    );
  }

  static Future<Map<String, dynamic>?> _getWeatherData(
      double latitude, double longitude) async {
    try {
      // Using a free weather API (you can replace with your preferred API)
      final response = await http
          .get(
            Uri.parse(
                'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=YOUR_API_KEY&units=metric'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temperature': data['main']['temp'].toDouble(),
          'humidity': data['main']['humidity'].toDouble(),
          'rainfall': data['rain']?['1h']?.toDouble() ?? 0.0,
        };
      }
    } catch (e) {
      print('Weather API error: $e');
    }
    return null;
  }

  static String _getClimateZone(double latitude, double longitude) {
    if (latitude.abs() < 23.5) {
      return 'tropical';
    } else if (latitude.abs() < 40) {
      return 'temperate';
    } else if (latitude.abs() < 60) {
      return 'continental';
    } else {
      return 'arid';
    }
  }

  // Default values based on latitude
  static double _getDefaultTemperature(double latitude) {
    return 30 - (latitude.abs() * 0.5);
  }

  static double _getDefaultHumidity(double latitude) {
    return 80 - (latitude.abs() * 0.3);
  }

  static double _getDefaultRainfall(double latitude) {
    if (latitude.abs() < 10) return 200.0;
    if (latitude.abs() < 30) return 150.0;
    if (latitude.abs() < 50) return 100.0;
    return 50.0;
  }

  static double _getDefaultPH(double latitude) {
    return 6.5 + (latitude.abs() * 0.01);
  }

  static double _getDefaultNitrogen(double latitude) {
    return 70 + (latitude.abs() * 0.2);
  }

  static double _getDefaultPhosphorus(double latitude) {
    return 45 + (latitude.abs() * 0.1);
  }

  static double _getDefaultPotassium(double latitude) {
    return 50 + (latitude.abs() * 0.15);
  }

  // Adjustment factors based on latitude
  static double _getLatitudeAdjustment(double latitude) {
    return (latitude.abs() - 30) * 0.1;
  }

  static double _getHumidityAdjustment(double latitude) {
    return (30 - latitude.abs()) * 0.5;
  }

  static double _getRainfallAdjustment(double latitude) {
    return (30 - latitude.abs()) * 2.0;
  }

  static double _getPHAdjustment(double latitude) {
    return (latitude.abs() - 30) * 0.01;
  }

  static double _getNitrogenAdjustment(double latitude) {
    return (30 - latitude.abs()) * 0.5;
  }

  static double _getPhosphorusAdjustment(double latitude) {
    return (30 - latitude.abs()) * 0.3;
  }

  static double _getPotassiumAdjustment(double latitude) {
    return (30 - latitude.abs()) * 0.4;
  }
}
