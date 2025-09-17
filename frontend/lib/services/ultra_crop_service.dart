import 'network_service.dart';
import '../config/app_config.dart';

class UltraCropService {
  // Base URL should be full origin, e.g. http://10.0.2.2:5020 or https://<cloud-run-url>
  static String get _baseUrl => AppConfig.baseUrl;

  /// Get Ultra Crop Recommendation
  static Future<Map<String, dynamic>> getUltraRecommendation({
    required double latitude,
    required double longitude,
    required String location,
    required double farmSize,
    required String irrigationType,
    List<String>? preferredCrops,
    Map<String, double>? soilData,
    String language = 'en',
  }) async {
    try {
      final requestData = {
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        'farm_size': farmSize,
        'irrigation_type': irrigationType,
        'language': language,
      };

      if (preferredCrops != null && preferredCrops.isNotEmpty) {
        requestData['preferred_crops'] = preferredCrops;
      }

      if (soilData != null && soilData.isNotEmpty) {
        requestData['soil_data'] = soilData;
      }

      final response = await NetworkService.post(
        '$_baseUrl/ultra-recommend',
        body: requestData,
        timeout: const Duration(seconds: 90),
      );

      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
        'error_type': 'network_error'
      };
    }
  }

  /// Get Quick Ultra Recommendation (minimal data)
  static Future<Map<String, dynamic>> getQuickRecommendation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final requestData = {
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await NetworkService.post(
        '$_baseUrl/ultra-recommend/quick',
        body: requestData,
        timeout: const Duration(seconds: 60),
      );

      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
        'error_type': 'network_error'
      };
    }
  }

  /// Get Enhanced Crop Database
  static Future<Map<String, dynamic>> getCropDatabase() async {
    try {
      final response =
          await NetworkService.get('$_baseUrl/ultra-recommend/crops');
      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
        'error_type': 'network_error'
      };
    }
  }

  /// Check API Health
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await NetworkService.get('$_baseUrl/health');
      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
        'error_type': 'network_error'
      };
    }
  }

  /// Format recommendation data for display
  static Map<String, dynamic> formatRecommendationForDisplay(
      Map<String, dynamic> rawData) {
    if (!rawData['success']) {
      return rawData;
    }

    final data = rawData['data'];
    final recommendation = data['recommendation'];
    final analysis = data['comprehensive_analysis'];

    return {
      'success': true,
      'formatted_data': {
        'primary_crop': recommendation['primary_recommendation'],
        'confidence': (recommendation['confidence'] * 100).round(),
        'location_info': {
          'name': data['location']['name'],
          'coordinates': data['location']['coordinates'],
          'farm_size': data['location']['farm_size_hectares'],
        },
        'key_metrics': {
          'soil_health': analysis['environmental_analysis']['soil_health'],
          'climate_suitability': analysis['environmental_analysis']
              ['climate_suitability'],
          'sustainability_score': analysis['sustainability_metrics']
              ['sustainability_score'],
          'expected_yield': analysis['economic_analysis']['yield_potential'],
          'roi_estimate': analysis['economic_analysis']['roi_estimate'],
        },
        'immediate_actions': data['actionable_insights']['immediate_actions'],
        'preparation_needed': data['actionable_insights']['preparation_needed'],
        'data_sources': data['data_sources'],
        'timestamp': data['timestamp'],
      }
    };
  }

  /// Get crop-specific information
  static Map<String, dynamic>? getCropInfo(
      Map<String, dynamic> cropDatabase, String cropName) {
    if (cropDatabase['success'] && cropDatabase['data'] != null) {
      final crops = cropDatabase['data']['crops'];
      return crops[cropName];
    }
    return null;
  }

  /// Calculate overall recommendation score
  static double calculateOverallScore(Map<String, dynamic> recommendationData) {
    if (!recommendationData['success']) return 0.0;

    final data = recommendationData['data'];
    final confidence = data['recommendation']['confidence'];
    final soilHealth = data['comprehensive_analysis']['environmental_analysis']
            ['soil_health'] /
        100;
    final sustainabilityScore = data['comprehensive_analysis']
            ['sustainability_metrics']['sustainability_score'] /
        10;

    // Weighted average of different factors
    return (confidence * 0.4 + soilHealth * 0.3 + sustainabilityScore * 0.3);
  }

  /// Get risk level based on analysis
  static String getRiskLevel(Map<String, dynamic> recommendationData) {
    if (!recommendationData['success']) return 'Unknown';

    final analysis = recommendationData['data']['comprehensive_analysis'];
    final riskAssessment = analysis['risk_assessment'];

    int riskFactors = 0;
    if (riskAssessment['disease_risk'] == 'High') riskFactors++;
    if (riskAssessment['climate_risk'] == 'High') riskFactors++;
    if (riskAssessment['market_risk'] == 'High') riskFactors++;

    if (riskFactors >= 2) return 'High';
    if (riskFactors == 1) return 'Medium';
    return 'Low';
  }

  /// Get color for confidence level
  static int getConfidenceColor(int confidence) {
    if (confidence >= 80) return 0xFF4CAF50; // Green
    if (confidence >= 60) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  /// Get emoji for crop type
  static String getCropEmoji(String cropName) {
    const cropEmojis = {
      'Rice': '🌾',
      'Wheat': '🌾',
      'Maize': '🌽',
      'Cotton': '🌸',
      'Sugarcane': '🎋',
      'Soybean': '🫘',
    };
    return cropEmojis[cropName] ?? '🌱';
  }

  /// Generate summary text for recommendation
  static String generateSummaryText(Map<String, dynamic> recommendationData) {
    if (!recommendationData['success']) {
      return 'Unable to generate recommendation summary.';
    }

    final data = recommendationData['data'];
    final crop = data['recommendation']['primary_recommendation'];
    final confidence = (data['recommendation']['confidence'] * 100).round();
    final yield =
        data['comprehensive_analysis']['economic_analysis']['yield_potential'];
    final roi =
        data['comprehensive_analysis']['economic_analysis']['roi_estimate'];

    return 'Based on AI analysis of your farm conditions, $crop is recommended with $confidence% confidence. Expected yield: $yield with ROI of $roi.';
  }
}
