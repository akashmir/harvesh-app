import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'error_handler.dart';
import 'retry_service.dart';

/// Satellite Soil Service
/// Provides real-time soil data from satellite imagery
class SatelliteSoilService {
  static final SatelliteSoilService _instance =
      SatelliteSoilService._internal();
  factory SatelliteSoilService() => _instance;
  SatelliteSoilService._internal();

  // Using static methods from ErrorHandler and RetryService

  /// Get current soil data for a location
  Future<Map<String, dynamic>> getCurrentSoilData({
    required double latitude,
    required double longitude,
    String? location,
  }) async {
    try {
      final params = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        if (location != null) 'location': location,
      };

      final uri = Uri.parse(AppConfig.satelliteSoilCurrentEndpoint).replace(
        queryParameters: params,
      );

      final response = await RetryService.retryRequest(
        () => http.get(uri),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get soil data: ${response.statusCode}');
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

  /// Get soil health analysis
  Future<Map<String, dynamic>> getSoilHealthAnalysis({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final params = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
      };

      final uri =
          Uri.parse(AppConfig.satelliteSoilHealthAnalysisEndpoint).replace(
        queryParameters: params,
      );

      final response = await RetryService.retryRequest(
        () => http.get(uri),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get soil health analysis: ${response.statusCode}');
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

  /// Get soil recommendations
  Future<Map<String, dynamic>> getSoilRecommendations({
    required double latitude,
    required double longitude,
    String? cropType,
  }) async {
    try {
      final params = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        if (cropType != null) 'crop_type': cropType,
      };

      final uri =
          Uri.parse(AppConfig.satelliteSoilRecommendationsEndpoint).replace(
        queryParameters: params,
      );

      final response = await RetryService.retryRequest(
        () => http.get(uri),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get soil recommendations: ${response.statusCode}');
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

  /// Get historical soil data
  Future<Map<String, dynamic>> getHistoricalSoilData({
    required double latitude,
    required double longitude,
    int? months,
  }) async {
    try {
      final params = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        if (months != null) 'months': months.toString(),
      };

      final uri = Uri.parse(AppConfig.satelliteSoilHistoricalEndpoint).replace(
        queryParameters: params,
      );

      final response = await RetryService.retryRequest(
        () => http.get(uri),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get historical soil data: ${response.statusCode}');
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

  /// Check service health
  Future<bool> checkHealth() async {
    try {
      final response = await RetryService.retryRequest(
        () => http.get(Uri.parse(AppConfig.satelliteSoilHealthEndpoint)),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
