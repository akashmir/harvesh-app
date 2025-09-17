import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'network_service.dart';
import 'location_service.dart';

/// Weather service with fallback to direct OpenWeatherMap API
class WeatherService {
  static const Duration _timeout = Duration(seconds: 10);

  /// Get current weather with automatic location detection
  static Future<Map<String, dynamic>> getCurrentWeatherAuto() async {
    try {
      // Try to get user's current location
      final position = await LocationService.getLocationWithFallback();

      if (position != null) {
        // Use coordinates for more accurate weather
        return await getCurrentWeatherByCoordinates(
            position.latitude, position.longitude);
      } else {
        // Fallback to default location if no GPS available
        return await getCurrentWeather('Mumbai');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location-based weather: $e');
      }
      // Fallback to default location
      return await getCurrentWeather('Mumbai');
    }
  }

  /// Get current weather by coordinates
  static Future<Map<String, dynamic>> getCurrentWeatherByCoordinates(
      double latitude, double longitude) async {
    try {
      // First try the backend API
      final backendResponse =
          await _getWeatherFromBackendByCoordinates(latitude, longitude);
      if (backendResponse['success'] == true) {
        // Normalize backend shape to match direct API shape
        final data = backendResponse['data'] as Map<String, dynamic>;
        final current = (data['current'] is Map)
            ? Map<String, dynamic>.from(data['current'] as Map)
            : <String, dynamic>{};
        String? label;
        try {
          label = await LocationService.getReadableLocationLabel(
              latitude, longitude);
        } catch (_) {}

        final normalized = <String, dynamic>{
          'temperature': (current['temperature'] ?? data['temperature'])?.toDouble(),
          'humidity': (current['humidity'] ?? data['humidity'])?.toDouble(),
          'description': (data['forecast'] is Map)
              ? (data['forecast']['weather_advisory'] ?? 'Weather')
              : 'Weather',
          'icon': null, // backend mock doesn't provide icon
          'wind_speed': (current['wind_speed'] ?? data['wind_speed'])?.toDouble(),
          'pressure': (current['pressure'] ?? data['pressure'])?.toDouble(),
          'visibility': data['visibility']?.toDouble(),
          'location': label ?? data['location']?.toString() ?? 'Current Location',
          'country': data['country'] ?? 'IN',
          'precise_location_label': label,
          'latitude': latitude,
          'longitude': longitude,
        };

        return {'success': true, 'data': normalized};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend weather API failed: $e');
      }
    }

    // Fallback to direct OpenWeatherMap API
    try {
      final directResponse =
          await _getWeatherFromOpenWeatherMapByCoordinates(latitude, longitude);
      try {
        final label =
            await LocationService.getReadableLocationLabel(latitude, longitude);
        directResponse['data']['precise_location_label'] = label;
      } catch (_) {}
      return directResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Direct weather API failed: $e');
      }
      return {
        'success': false,
        'error': 'Weather service unavailable',
        'data': _getFallbackWeatherData('Current Location'),
      };
    }
  }

  /// Get current weather with fallback
  static Future<Map<String, dynamic>> getCurrentWeather(String location) async {
    try {
      // First try the backend API
      final backendResponse = await _getWeatherFromBackend(location);
      if (backendResponse['success'] == true) {
        // Normalize backend shape to match direct API shape
        final data = backendResponse['data'] as Map<String, dynamic>;
        final current = (data['current'] is Map)
            ? Map<String, dynamic>.from(data['current'] as Map)
            : <String, dynamic>{};
        final normalized = <String, dynamic>{
          'temperature': (current['temperature'] ?? data['temperature'])?.toDouble(),
          'humidity': (current['humidity'] ?? data['humidity'])?.toDouble(),
          'description': (data['forecast'] is Map)
              ? (data['forecast']['weather_advisory'] ?? 'Weather')
              : 'Weather',
          'icon': null,
          'wind_speed': (current['wind_speed'] ?? data['wind_speed'])?.toDouble(),
          'pressure': (current['pressure'] ?? data['pressure'])?.toDouble(),
          'visibility': data['visibility']?.toDouble(),
          'location': location,
          'country': data['country'] ?? 'IN',
          'precise_location_label': location,
        };
        return {'success': true, 'data': normalized};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend weather API failed: $e');
      }
    }

    // Fallback to direct OpenWeatherMap API
    try {
      final directResponse = await _getWeatherFromOpenWeatherMap(location);
      return directResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Direct weather API failed: $e');
      }
      return {
        'success': false,
        'error': 'Weather service unavailable',
        'data': _getFallbackWeatherData(location),
      };
    }
  }

  /// Try to get weather from backend API
  static Future<Map<String, dynamic>> _getWeatherFromBackend(
      String location) async {
    final response = await NetworkService.get(
      '${AppConfig.weatherIntegrationApiBaseUrl}/weather/current?location=$location',
      timeout: _timeout,
    );

    return response;
  }

  /// Get weather directly from OpenWeatherMap API
  static Future<Map<String, dynamic>> _getWeatherFromOpenWeatherMap(
      String location) async {
    if (!AppConfig.isWeatherApiKeyValid) {
      throw Exception('Weather API key not configured');
    }

    final apiKey = AppConfig.weatherApiKey;
    final url =
        '${AppConfig.weatherCurrentEndpoint}?q=$location&appid=$apiKey&units=metric';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'data': {
          'temperature': data['main']['temp'],
          'humidity': data['main']['humidity'],
          'description': data['weather'][0]['description'],
          'icon': data['weather'][0]['icon'],
          'wind_speed': data['wind']['speed'],
          'pressure': data['main']['pressure'],
          'visibility': data['visibility'] / 1000, // Convert to km
          'location': data['name'],
          'country': data['sys']['country'],
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
    } else if (response.statusCode == 404) {
      throw Exception('Location not found');
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API key');
    } else {
      throw Exception('Weather API error: ${response.statusCode}');
    }
  }

  /// Get fallback weather data when all APIs fail
  static Map<String, dynamic> _getFallbackWeatherData(String location) {
    return {
      'temperature': 25.0,
      'humidity': 60.0,
      'description': 'Weather data unavailable',
      'icon': '01d',
      'wind_speed': 5.0,
      'pressure': 1013.0,
      'visibility': 10.0,
      'location': location,
      'country': 'IN',
      'timestamp': DateTime.now().toIso8601String(),
      'is_fallback': true,
    };
  }

  /// Get weather forecast with fallback
  static Future<Map<String, dynamic>> getWeatherForecast(String location,
      {int days = 5}) async {
    try {
      // First try the backend API
      final backendResponse = await NetworkService.get(
        '${AppConfig.weatherIntegrationApiBaseUrl}/weather/forecast?location=$location&days=$days',
        timeout: _timeout,
      );

      if (backendResponse['success']) {
        return backendResponse;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend forecast API failed: $e');
      }
    }

    // Fallback to direct OpenWeatherMap API
    try {
      final directResponse = await _getForecastFromOpenWeatherMap(location);
      return directResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Direct forecast API failed: $e');
      }
      return {
        'success': false,
        'error': 'Weather forecast unavailable',
        'data': {
          'forecasts': _getFallbackForecastData(days),
        },
      };
    }
  }

  /// Get forecast directly from OpenWeatherMap API
  static Future<Map<String, dynamic>> _getForecastFromOpenWeatherMap(
      String location) async {
    if (!AppConfig.isWeatherApiKeyValid) {
      throw Exception('Weather API key not configured');
    }

    final apiKey = AppConfig.weatherApiKey;
    final url =
        '${AppConfig.weatherForecastEndpoint}?q=$location&appid=$apiKey&units=metric';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final forecasts = <Map<String, dynamic>>[];

      // Process 5-day forecast (every 8th item = daily)
      for (int i = 0; i < data['list'].length && i < 40; i += 8) {
        final item = data['list'][i];
        forecasts.add({
          'date': DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000)
              .toIso8601String(),
          'temperature': item['main']['temp'],
          'humidity': item['main']['humidity'],
          'description': item['weather'][0]['description'],
          'icon': item['weather'][0]['icon'],
          'wind_speed': item['wind']['speed'],
          'pressure': item['main']['pressure'],
        });
      }

      return {
        'success': true,
        'data': {
          'forecasts': forecasts,
          'location': data['city']['name'],
          'country': data['city']['country'],
        },
      };
    } else {
      throw Exception('Weather forecast API error: ${response.statusCode}');
    }
  }

  /// Get fallback forecast data
  static List<Map<String, dynamic>> _getFallbackForecastData(int days) {
    final forecasts = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i));
      forecasts.add({
        'date': date.toIso8601String(),
        'temperature': 25.0 + (i * 2),
        'humidity': 60.0 - (i * 2),
        'description': 'Weather data unavailable',
        'icon': '01d',
        'wind_speed': 5.0,
        'pressure': 1013.0,
        'is_fallback': true,
      });
    }

    return forecasts;
  }

  /// Check if weather service is available
  static Future<bool> isWeatherServiceAvailable() async {
    try {
      // Try backend first
      final backendResponse = await NetworkService.get(
        '${AppConfig.weatherIntegrationApiBaseUrl}/health',
        timeout: const Duration(seconds: 5),
      );
      return backendResponse['success'] == true;
    } catch (e) {
      // If backend fails, check if we have valid API key for direct access
      return AppConfig.isWeatherApiKeyValid;
    }
  }

  /// Get weather service status
  static Future<Map<String, dynamic>> getWeatherServiceStatus() async {
    final status = <String, dynamic>{
      'backend_available': false,
      'direct_api_available': false,
      'api_key_valid': AppConfig.isWeatherApiKeyValid,
      'fallback_available': true,
    };

    try {
      // Check backend
      final backendResponse = await NetworkService.get(
        '${AppConfig.weatherIntegrationApiBaseUrl}/health',
        timeout: const Duration(seconds: 5),
      );
      status['backend_available'] = backendResponse['success'] == true;
    } catch (e) {
      status['backend_error'] = e.toString();
    }

    // Direct API is available if we have a valid API key
    status['direct_api_available'] = AppConfig.isWeatherApiKeyValid;

    return status;
  }

  /// Try to get weather from backend API by coordinates
  static Future<Map<String, dynamic>> _getWeatherFromBackendByCoordinates(
      double latitude, double longitude) async {
    final response = await NetworkService.get(
      '${AppConfig.weatherIntegrationApiBaseUrl}/weather/current?lat=$latitude&lon=$longitude',
      timeout: _timeout,
    );

    return response;
  }

  /// Get weather directly from OpenWeatherMap API by coordinates
  static Future<Map<String, dynamic>>
      _getWeatherFromOpenWeatherMapByCoordinates(
          double latitude, double longitude) async {
    if (!AppConfig.isWeatherApiKeyValid) {
      throw Exception('Weather API key not configured');
    }

    final apiKey = AppConfig.weatherApiKey;
    final url =
        '${AppConfig.weatherCurrentEndpoint}?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'data': {
          'temperature': data['main']['temp'],
          'humidity': data['main']['humidity'],
          'description': data['weather'][0]['description'],
          'icon': data['weather'][0]['icon'],
          'wind_speed': data['wind']['speed'],
          'pressure': data['main']['pressure'],
          'visibility': data['visibility'] / 1000, // Convert to km
          'location': data['name'],
          'country': data['sys']['country'],
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
    } else if (response.statusCode == 404) {
      throw Exception('Location not found');
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API key');
    } else {
      throw Exception('Weather API error: ${response.statusCode}');
    }
  }
}
