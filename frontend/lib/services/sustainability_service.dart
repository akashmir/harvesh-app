import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'error_handler.dart';
import 'retry_service.dart';

/// Sustainability Scoring Service
/// Provides environmental impact analysis and eco-friendly recommendations
class SustainabilityService {
  static final SustainabilityService _instance =
      SustainabilityService._internal();
  factory SustainabilityService() => _instance;
  SustainabilityService._internal();

  // Using static methods from ErrorHandler and RetryService

  /// Calculate sustainability score for farming practices
  Future<Map<String, dynamic>> calculateSustainabilityScore({
    required Map<String, dynamic> farmingPractices,
    required Map<String, dynamic> fieldData,
    String? cropType,
  }) async {
    try {
      final requestData = {
        'farming_practices': farmingPractices,
        'field_data': fieldData,
        if (cropType != null) 'crop_type': cropType,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.sustainabilityScoringCalculateEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to calculate sustainability score: ${response.statusCode}');
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

  /// Get sustainability recommendations
  Future<List<Map<String, dynamic>>> getSustainabilityRecommendations({
    required Map<String, dynamic> currentPractices,
    required String cropType,
    String? language = 'en',
  }) async {
    try {
      final requestData = {
        'current_practices': currentPractices,
        'crop_type': cropType,
        'language': language!,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.sustainabilityScoringRecommendationsEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
      } else {
        throw Exception(
            'Failed to get sustainability recommendations: ${response.statusCode}');
      }
    } catch (e) {
      final error = ErrorHandler.handleError(e);
      return [
        {
          'error': error.userFriendlyMessage,
          'details': error.message,
        }
      ];
    }
  }

  /// Calculate carbon footprint
  Future<Map<String, dynamic>> calculateCarbonFootprint({
    required Map<String, dynamic> farmingData,
    required String cropType,
    int? season,
  }) async {
    try {
      final requestData = {
        'farming_data': farmingData,
        'crop_type': cropType,
        if (season != null) 'season': season,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.sustainabilityScoringCarbonFootprintEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to calculate carbon footprint: ${response.statusCode}');
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

  /// Get eco-friendly farming practices
  Future<List<Map<String, dynamic>>> getEcoFriendlyPractices({
    required String cropType,
    String? region,
    String? language = 'en',
  }) async {
    try {
      final params = {
        'crop_type': cropType,
        'language': language!,
        if (region != null) 'region': region,
      };

      final uri =
          Uri.parse(AppConfig.sustainabilityScoringRecommendationsEndpoint)
              .replace(
        queryParameters: params,
      );

      final response = await RetryService.retryRequest(
        () => http.get(uri),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['practices'] ?? []);
      } else {
        throw Exception(
            'Failed to get eco-friendly practices: ${response.statusCode}');
      }
    } catch (e) {
      final error = ErrorHandler.handleError(e);
      return [
        {
          'error': error.userFriendlyMessage,
          'details': error.message,
        }
      ];
    }
  }

  /// Get water usage optimization tips
  Future<List<String>> getWaterOptimizationTips({
    required String cropType,
    required Map<String, dynamic> fieldConditions,
  }) async {
    try {
      final requestData = {
        'crop_type': cropType,
        'field_conditions': fieldConditions,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.sustainabilityScoringRecommendationsEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['water_optimization_tips'] ?? []);
      } else {
        throw Exception(
            'Failed to get water optimization tips: ${response.statusCode}');
      }
    } catch (e) {
      final error = ErrorHandler.handleError(e);
      return [error.userFriendlyMessage];
    }
  }

  /// Get soil health improvement recommendations
  Future<List<String>> getSoilHealthRecommendations({
    required Map<String, dynamic> soilData,
    required String cropType,
  }) async {
    try {
      final requestData = {
        'soil_data': soilData,
        'crop_type': cropType,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.sustainabilityScoringRecommendationsEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['soil_health_recommendations'] ?? []);
      } else {
        throw Exception(
            'Failed to get soil health recommendations: ${response.statusCode}');
      }
    } catch (e) {
      final error = ErrorHandler.handleError(e);
      return [error.userFriendlyMessage];
    }
  }

  /// Check service health
  Future<bool> checkHealth() async {
    try {
      final response = await RetryService.retryRequest(
        () =>
            http.get(Uri.parse(AppConfig.sustainabilityScoringHealthEndpoint)),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
