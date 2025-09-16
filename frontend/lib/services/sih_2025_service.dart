import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'error_handler.dart';
import 'retry_service.dart';

/// Additional Features Integrated Service
/// Provides access to all enhanced farming features
class Sih2025Service {
  static final Sih2025Service _instance = Sih2025Service._internal();
  factory Sih2025Service() => _instance;
  Sih2025Service._internal();

  // Using static methods from ErrorHandler and RetryService

  /// Get comprehensive crop recommendation with all advanced features
  Future<Map<String, dynamic>> getComprehensiveRecommendation({
    required Map<String, dynamic> soilData,
    required Map<String, dynamic> weatherData,
    required Map<String, dynamic> locationData,
    String? previousCrop,
    String? language = 'en',
  }) async {
    try {
      final requestData = {
        'soil_data': soilData,
        'weather_data': weatherData,
        'location_data': locationData,
        'previous_crop': previousCrop,
        'language': language,
        'include_sustainability': true,
        'include_market_analysis': true,
        'include_offline_data': true,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.sih2025IntegratedComprehensiveEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get comprehensive recommendation: ${response.statusCode}');
      }
    } catch (e) {
      final error = ErrorHandler.handleError(e);
      return {
        'success': false,
        'error': error.userFriendlyMessage,
        'details': error.message,
      };
    }
  }

  /// Get basic crop recommendation
  Future<Map<String, dynamic>> getCropRecommendation({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double ph,
    required double rainfall,
    String? model = 'random_forest',
  }) async {
    try {
      final requestData = {
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'temperature': temperature,
        'humidity': humidity,
        'ph': ph,
        'rainfall': rainfall,
        'model': model,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.sih2025IntegratedRecommendEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get crop recommendation: ${response.statusCode}');
      }
    } catch (e) {
      final error = ErrorHandler.handleError(e);
      return {
        'success': false,
        'error': error.userFriendlyMessage,
        'details': error.message,
      };
    }
  }

  /// Check system health
  Future<Map<String, dynamic>> checkSystemHealth() async {
    try {
      final response = await RetryService.retryRequest(
        () => http.get(
          Uri.parse(AppConfig.sih2025IntegratedHealthEndpoint),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to check system health: ${response.statusCode}');
      }
    } catch (e) {
      final error = ErrorHandler.handleError(e);
      return {
        'success': false,
        'error': error.userFriendlyMessage,
        'details': error.message,
      };
    }
  }

  /// Get available features
  Future<List<String>> getAvailableFeatures() async {
    try {
      final healthData = await checkSystemHealth();
      return List<String>.from(healthData['features'] ?? []);
    } catch (e) {
      final error = ErrorHandler.handleError(e);
      return [error.userFriendlyMessage];
    }
  }
}
