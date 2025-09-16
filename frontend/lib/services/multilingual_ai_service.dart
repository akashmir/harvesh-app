import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'error_handler.dart';
import 'retry_service.dart';

/// Multilingual AI Service
/// Provides voice and chat interfaces in local languages
class MultilingualAiService {
  static final MultilingualAiService _instance =
      MultilingualAiService._internal();
  factory MultilingualAiService() => _instance;
  MultilingualAiService._internal();

  // Using static methods from ErrorHandler and RetryService

  /// Send chat message in any supported language
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    required String language,
    String? context,
  }) async {
    try {
      final requestData = {
        'message': message,
        'language': language,
        if (context != null) 'context': context,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.multilingualAiChatEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send chat message: ${response.statusCode}');
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

  /// Process voice input
  Future<Map<String, dynamic>> processVoiceInput({
    required String audioData,
    required String language,
  }) async {
    try {
      final requestData = {
        'audio_data': audioData,
        'language': language,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.multilingualAiVoiceEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to process voice input: ${response.statusCode}');
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

  /// Get supported languages
  Future<List<String>> getSupportedLanguages() async {
    try {
      final response = await RetryService.retryRequest(
        () => http.get(Uri.parse(AppConfig.multilingualAiLanguagesEndpoint)),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['languages'] ?? []);
      } else {
        throw Exception(
            'Failed to get supported languages: ${response.statusCode}');
      }
    } catch (e) {
      final error = ErrorHandler.handleError(e);
      return [error.userFriendlyMessage];
    }
  }

  /// Translate text
  Future<Map<String, dynamic>> translateText({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    try {
      final requestData = {
        'text': text,
        'from_language': fromLanguage,
        'to_language': toLanguage,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.multilingualAiTranslateEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to translate text: ${response.statusCode}');
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

  /// Get agricultural advice in local language
  Future<Map<String, dynamic>> getAgriculturalAdvice({
    required String query,
    required String language,
    Map<String, dynamic>? context,
  }) async {
    try {
      final requestData = {
        'query': query,
        'language': language,
        if (context != null) 'context': context,
      };

      final response = await RetryService.retryRequest(
        () => http.post(
          Uri.parse(AppConfig.multilingualAiChatEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        ),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get agricultural advice: ${response.statusCode}');
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
        () => http.get(Uri.parse(AppConfig.multilingualAiHealthEndpoint)),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
