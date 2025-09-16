import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'error_handler.dart';
import 'retry_service.dart';

/// AI Disease Detection Service
/// Provides advanced plant disease and pest detection
class AiDiseaseDetectionService {
  static final AiDiseaseDetectionService _instance =
      AiDiseaseDetectionService._internal();
  factory AiDiseaseDetectionService() => _instance;
  AiDiseaseDetectionService._internal();

  // Using static methods from ErrorHandler and RetryService

  /// Analyze plant image for diseases and pests
  Future<Map<String, dynamic>> analyzePlantImage({
    required File imageFile,
    String? cropType,
    String? language = 'en',
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.diseaseDetectionAnalyzeEndpoint),
      );

      request.fields['crop_type'] = cropType ?? 'unknown';
      request.fields['language'] = language!;

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));

      final streamedResponse = await RetryService.retryRequest(
        () => request.send(),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to analyze plant image: ${response.statusCode}');
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

  /// Get available diseases for a crop
  Future<List<Map<String, dynamic>>> getDiseasesForCrop({
    required String cropType,
    String? language = 'en',
  }) async {
    try {
      final params = {
        'crop': cropType,
        'language': language!,
      };

      final uri = Uri.parse(AppConfig.diseaseDetectionDiseasesEndpoint).replace(
        queryParameters: params,
      );

      final response = await RetryService.retryRequest(
        () => http.get(uri),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['diseases'] ?? []);
      } else {
        throw Exception('Failed to get diseases: ${response.statusCode}');
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

  /// Get available pests for a crop
  Future<List<Map<String, dynamic>>> getPestsForCrop({
    required String cropType,
    String? language = 'en',
  }) async {
    try {
      final params = {
        'crop': cropType,
        'language': language!,
      };

      final uri = Uri.parse(AppConfig.diseaseDetectionPestsEndpoint).replace(
        queryParameters: params,
      );

      final response = await RetryService.retryRequest(
        () => http.get(uri),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['pests'] ?? []);
      } else {
        throw Exception('Failed to get pests: ${response.statusCode}');
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

  /// Get treatment recommendations
  Future<Map<String, dynamic>> getTreatmentRecommendations({
    required String diseaseOrPestId,
    required String cropType,
    String? language = 'en',
  }) async {
    try {
      final requestData = {
        'disease_or_pest_id': diseaseOrPestId,
        'crop_type': cropType,
        'language': language!,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.diseaseDetectionTreatmentEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get treatment recommendations: ${response.statusCode}');
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

  /// Get disease prevention tips
  Future<List<String>> getDiseasePreventionTips({
    required String cropType,
    String? language = 'en',
  }) async {
    try {
      final diseases =
          await getDiseasesForCrop(cropType: cropType, language: language);
      final preventionTips = <String>[];

      for (final disease in diseases) {
        final prevention = disease['prevention'] as List<dynamic>?;
        if (prevention != null) {
          preventionTips.addAll(prevention.cast<String>());
        }
      }

      return preventionTips.toSet().toList(); // Remove duplicates
    } catch (e) {
      final error = ErrorHandler.handleError(e);
      return [error.userFriendlyMessage];
    }
  }

  /// Check service health
  Future<bool> checkHealth() async {
    try {
      final response = await RetryService.retryRequest(
        () => http.get(Uri.parse(AppConfig.diseaseDetectionHealthEndpoint)),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
