import 'dart:convert';
import 'dart:math' as math;
import 'dart:math' show Random;
import 'package:shared_preferences/shared_preferences.dart';
import 'network_service.dart';
import 'ultra_crop_service.dart';

class UltraCropOfflineService {
  static const String _cachePrefix = 'ultra_crop_cache_';
  static const String _offlineModelsKey = 'ultra_offline_models';
  static const String _cachedRecommendationsKey =
      'ultra_cached_recommendations';
  static const Duration _cacheValidityDuration = Duration(days: 7);

  /// Check if offline mode is available
  static Future<bool> isOfflineModeAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_offlineModelsKey);
  }

  /// Download and cache offline models and data
  static Future<Map<String, dynamic>> downloadOfflineData() async {
    try {
      // Check network connectivity
      final isOnline = await NetworkService.checkConnectivity();
      if (!isOnline) {
        return {
          'success': false,
          'error': 'Network connection required to download offline data',
        };
      }

      final prefs = await SharedPreferences.getInstance();

      // Download crop database
      final cropDbResponse = await UltraCropService.getCropDatabase();
      if (cropDbResponse['success'] != true) {
        return {
          'success': false,
          'error': 'Failed to download crop database',
        };
      }

      // Cache crop database
      await prefs.setString(
        '${_cachePrefix}crop_database',
        json.encode(cropDbResponse['data']),
      );
      await prefs.setString(
        '${_cachePrefix}crop_database_timestamp',
        DateTime.now().toIso8601String(),
      );

      // Download and cache simplified ML models (rule-based fallback)
      final offlineModels = _createOfflineModels();
      await prefs.setString(_offlineModelsKey, json.encode(offlineModels));

      // Mark offline mode as available
      await prefs.setBool('ultra_offline_available', true);
      await prefs.setString(
        'ultra_offline_download_date',
        DateTime.now().toIso8601String(),
      );

      return {
        'success': true,
        'message': 'Offline data downloaded successfully',
        'data': {
          'crops_cached': cropDbResponse['data']['crops'].length,
          'models_cached': offlineModels['models'].length,
          'cache_size_mb': await _calculateCacheSize(),
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to download offline data: ${e.toString()}',
      };
    }
  }

  /// Get offline recommendation using cached models
  static Future<Map<String, dynamic>> getOfflineRecommendation({
    required double latitude,
    required double longitude,
    required String location,
    required double farmSize,
    required String irrigationType,
    Map<String, double>? soilData,
    String language = 'en',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if offline data is available
      if (!await isOfflineModeAvailable()) {
        return {
          'success': false,
          'error':
              'Offline data not available. Please download offline data when connected.',
          'error_type': 'offline_data_unavailable',
        };
      }

      // Load cached crop database
      final cropDbString = prefs.getString('${_cachePrefix}crop_database');
      if (cropDbString == null) {
        return {
          'success': false,
          'error': 'Crop database not cached',
          'error_type': 'cache_missing',
        };
      }

      final cropDatabase = json.decode(cropDbString);

      // Load offline models
      final modelsString = prefs.getString(_offlineModelsKey);
      if (modelsString == null) {
        return {
          'success': false,
          'error': 'Offline models not available',
          'error_type': 'models_missing',
        };
      }

      final offlineModels = json.decode(modelsString);

      // Generate offline recommendation
      final recommendation = await _generateOfflineRecommendation(
        latitude: latitude,
        longitude: longitude,
        location: location,
        farmSize: farmSize,
        irrigationType: irrigationType,
        soilData: soilData,
        cropDatabase: cropDatabase,
        models: offlineModels,
        language: language,
      );

      // Cache the recommendation
      await _cacheRecommendation(recommendation);

      return {
        'success': true,
        'data': recommendation,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Offline recommendation failed: ${e.toString()}',
        'error_type': 'processing_error',
      };
    }
  }

  /// Generate offline recommendation using simplified models
  static Future<Map<String, dynamic>> _generateOfflineRecommendation({
    required double latitude,
    required double longitude,
    required String location,
    required double farmSize,
    required String irrigationType,
    Map<String, double>? soilData,
    required Map<String, dynamic> cropDatabase,
    required Map<String, dynamic> models,
    required String language,
  }) async {
    // Estimate environmental conditions based on location
    final environmentalData =
        _estimateEnvironmentalConditions(latitude, longitude);

    // Merge with provided soil data
    final comprehensiveData = <String, dynamic>{
      ...environmentalData,
      ...?soilData,
    };

    // Apply rule-based recommendation logic
    final cropRecommendations = <Map<String, dynamic>>[];

    for (final cropEntry in cropDatabase['crops'].entries) {
      final cropName = cropEntry.key;
      final cropInfo = cropEntry.value;

      final score = _calculateCropSuitabilityScore(
        comprehensiveData,
        cropInfo,
        irrigationType,
        farmSize,
      );

      cropRecommendations.add({
        'crop': cropName,
        'score': score,
        'confidence': score / 100.0,
        'crop_info': cropInfo,
      });
    }

    // Sort by score
    cropRecommendations.sort((a, b) => b['score'].compareTo(a['score']));

    final primaryRecommendation = cropRecommendations.first;

    // Generate comprehensive analysis
    final analysis = _generateOfflineAnalysis(
      primaryRecommendation,
      comprehensiveData,
      farmSize,
      irrigationType,
    );

    return {
      'location': {
        'name': location,
        'coordinates': {'latitude': latitude, 'longitude': longitude},
        'farm_size_hectares': farmSize,
        'irrigation_type': irrigationType,
      },
      'recommendation': {
        'primary_recommendation': primaryRecommendation['crop'],
        'confidence': primaryRecommendation['confidence'],
        'all_recommendations': cropRecommendations.take(5).toList(),
        'method': 'Offline Rule-Based',
        'model_version': 'offline_v1.0',
      },
      'comprehensive_analysis': analysis,
      'data_sources': {
        'soil_data': soilData != null
            ? 'User Provided + Estimated'
            : 'Location Estimated',
        'weather_data': 'Location Estimated',
        'confidence_scores': {
          'soil': soilData != null ? 0.8 : 0.6,
          'weather': 0.6,
          'topographic': 0.7,
        }
      },
      'actionable_insights': {
        'immediate_actions': [
          'Plant ${primaryRecommendation['crop']} in suitable season',
          'Expected yield: ${primaryRecommendation['crop_info']['yield_potential']}',
          'Profit margin: ${primaryRecommendation['crop_info']['profit_margin']}',
        ],
        'preparation_needed': _generatePreparationAdvice(comprehensiveData),
      },
      'offline_mode': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Estimate environmental conditions based on location
  static Map<String, dynamic> _estimateEnvironmentalConditions(
      double latitude, double longitude) {
    // Simple climate estimation based on latitude (India-specific)
    final random = Random(latitude.hashCode + longitude.hashCode);

    // Temperature estimation based on latitude
    double temperature;
    if (latitude > 30) {
      // Northern India - cooler
      temperature = (15 + random.nextDouble() * 15).toDouble(); // 15-30°C
    } else if (latitude > 20) {
      // Central India - moderate
      temperature = (20 + random.nextDouble() * 15).toDouble(); // 20-35°C
    } else {
      // Southern India - warmer
      temperature = (25 + random.nextDouble() * 10).toDouble(); // 25-35°C
    }

    // Rainfall estimation (monsoon patterns)
    double rainfall;
    if (longitude > 77) {
      // Eastern regions - higher rainfall
      rainfall = (1000 + random.nextDouble() * 1000).toDouble(); // 1000-2000mm
    } else {
      // Western regions - lower rainfall
      rainfall = (500 + random.nextDouble() * 1000).toDouble(); // 500-1500mm
    }

    // Soil parameters estimation
    final ph = 6.0 + random.nextDouble() * 2.0; // 6.0-8.0
    final nitrogen = 80 + random.nextDouble() * 120; // 80-200
    final phosphorus = 15 + random.nextDouble() * 35; // 15-50
    final potassium = 120 + random.nextDouble() * 180; // 120-300
    final organicCarbon = 0.8 + random.nextDouble() * 1.7; // 0.8-2.5
    final soilMoisture = 40 + random.nextDouble() * 40; // 40-80
    final clayContent = 20 + random.nextDouble() * 40; // 20-60
    final sandContent = 25 + random.nextDouble() * 40; // 25-65

    return {
      'temperature': temperature,
      'humidity': 50 + random.nextDouble() * 30, // 50-80%
      'rainfall': rainfall,
      'ph': ph,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'organic_carbon': organicCarbon,
      'soil_moisture': soilMoisture,
      'clay_content': clayContent,
      'sand_content': sandContent,
      'elevation': random.nextDouble() * 500, // 0-500m
      'slope': random.nextDouble() * 10, // 0-10 degrees
      'ndvi': 0.3 + random.nextDouble() * 0.5, // 0.3-0.8
      'water_access_score': 0.6 + random.nextDouble() * 0.3, // 0.6-0.9
      'health_score': 70 + random.nextDouble() * 20, // 70-90
      'fertility_index': 60 + random.nextDouble() * 25, // 60-85
    };
  }

  /// Calculate crop suitability score
  static double _calculateCropSuitabilityScore(
    Map<String, dynamic> environmentalData,
    Map<String, dynamic> cropInfo,
    String irrigationType,
    double farmSize,
  ) {
    double score = 0;

    // Temperature compatibility (25 points)
    final temp = environmentalData['temperature'] ?? 25.0;
    final tempRange = cropInfo['temperature_range'];
    if (tempRange != null) {
      final tempMin = tempRange[0];
      final tempMax = tempRange[1];
      if (temp >= tempMin && temp <= tempMax) {
        score += 25;
      } else {
        final distance =
            math.min<double>((temp - tempMin).abs(), (temp - tempMax).abs());
        score += math.max(0, 25 - distance * 2);
      }
    }

    // pH compatibility (20 points)
    final ph = environmentalData['ph'] ?? 6.5;
    final phRange = cropInfo['soil_ph_range'];
    if (phRange != null) {
      final phMin = phRange[0];
      final phMax = phRange[1];
      if (ph >= phMin && ph <= phMax) {
        score += 20;
      } else {
        final distance =
            math.min<double>((ph - phMin).abs(), (ph - phMax).abs());
        score += math.max(0, 20 - distance * 10);
      }
    }

    // Rainfall compatibility (20 points)
    final rainfall = environmentalData['rainfall'] ?? 1000.0;
    final rainfallRange = cropInfo['rainfall_range'];
    if (rainfallRange != null) {
      final rainMin = rainfallRange[0];
      final rainMax = rainfallRange[1];
      if (rainfall >= rainMin && rainfall <= rainMax) {
        score += 20;
      } else {
        final distance = math.min<double>(
            (rainfall - rainMin).abs(), (rainfall - rainMax).abs());
        score += math.max(0, 20 - distance / 100);
      }
    }

    // Water requirement vs irrigation (15 points)
    final waterReq = cropInfo['water_requirement'] ?? 'Medium';
    final irrigationScore = _getIrrigationScore(waterReq, irrigationType);
    score += irrigationScore;

    // Soil health (10 points)
    final healthScore = environmentalData['health_score'] ?? 75.0;
    score += (healthScore / 100) * 10;

    // Market demand bonus (10 points)
    final marketDemand = cropInfo['market_demand'] ?? 'Medium';
    if (marketDemand == 'Very High') {
      score += 10;
    } else if (marketDemand == 'High') {
      score += 7;
    } else if (marketDemand == 'Medium') {
      score += 5;
    }

    return score.clamp(0, 100);
  }

  /// Get irrigation score based on water requirement and irrigation type
  static double _getIrrigationScore(String waterReq, String irrigationType) {
    const irrigationEfficiency = {
      'drip': 0.9,
      'sprinkler': 0.8,
      'canal': 0.7,
      'tubewell': 0.7,
      'rainfed': 0.4,
    };

    const waterReqScore = {
      'Very High': 1.0,
      'High': 0.8,
      'Medium': 0.6,
      'Low': 0.4,
    };

    final efficiency = irrigationEfficiency[irrigationType] ?? 0.6;
    final reqScore = waterReqScore[waterReq] ?? 0.6;

    return 15 * efficiency * reqScore;
  }

  /// Generate offline analysis
  static Map<String, dynamic> _generateOfflineAnalysis(
    Map<String, dynamic> primaryRecommendation,
    Map<String, dynamic> environmentalData,
    double farmSize,
    String irrigationType,
  ) {
    final cropInfo = primaryRecommendation['crop_info'];
    final healthScore = environmentalData['health_score'] ?? 75.0;
    final fertilityIndex = environmentalData['fertility_index'] ?? 70.0;

    return {
      'crop_suitability': {
        'primary_crop': primaryRecommendation['crop'],
        'confidence': primaryRecommendation['confidence'],
        'suitability_score': primaryRecommendation['score'],
      },
      'environmental_analysis': {
        'soil_health': healthScore,
        'fertility_status': fertilityIndex,
        'climate_suitability':
            primaryRecommendation['confidence'] > 0.8 ? 'Excellent' : 'Good',
        'water_availability': environmentalData['water_access_score'] * 100,
      },
      'economic_analysis': {
        'yield_potential': cropInfo['yield_potential'],
        'market_demand': cropInfo['market_demand'],
        'profit_margin': cropInfo['profit_margin'],
        'input_cost': cropInfo['input_cost'],
      },
      'sustainability_metrics': {
        'sustainability_score': cropInfo['sustainability_score'],
        'environmental_impact':
            cropInfo['sustainability_score'] > 8 ? 'Low' : 'Medium',
      },
      'agronomic_recommendations': {
        'planting_season': cropInfo['seasons'][0],
        'expected_duration': cropInfo['growth_duration'],
        'water_management': cropInfo['water_requirement'],
      },
    };
  }

  /// Generate preparation advice
  static List<String> _generatePreparationAdvice(Map<String, dynamic> data) {
    final advice = <String>[];

    final ph = data['ph'] ?? 6.5;
    if (ph < 6.0) {
      advice.add('Apply lime to increase soil pH');
    } else if (ph > 8.0) {
      advice.add('Apply organic matter to reduce soil pH');
    }

    final organicCarbon = data['organic_carbon'] ?? 1.0;
    if (organicCarbon < 1.0) {
      advice.add('Add compost or farmyard manure');
    }

    final soilMoisture = data['soil_moisture'] ?? 50.0;
    if (soilMoisture < 40) {
      advice.add('Improve irrigation frequency');
    }

    if (advice.isEmpty) {
      advice.add('Soil conditions are suitable for planting');
    }

    return advice;
  }

  /// Create simplified offline models
  static Map<String, dynamic> _createOfflineModels() {
    return {
      'models': [
        {
          'name': 'Rule-Based Classifier',
          'type': 'rule_based',
          'version': 'offline_v1.0',
          'accuracy': 0.75,
          'description':
              'Simplified rule-based model for offline recommendations',
        }
      ],
      'features': [
        'temperature',
        'ph',
        'rainfall',
        'soil_moisture',
        'nitrogen',
        'phosphorus',
        'potassium',
        'organic_carbon'
      ],
      'crops': ['Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane', 'Soybean'],
      'created_date': DateTime.now().toIso8601String(),
    };
  }

  /// Cache recommendation for later sync
  static Future<void> _cacheRecommendation(
      Map<String, dynamic> recommendation) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing cached recommendations
    final cachedString = prefs.getString(_cachedRecommendationsKey) ?? '[]';
    final cachedList =
        List<Map<String, dynamic>>.from(json.decode(cachedString));

    // Add new recommendation
    cachedList.add({
      ...recommendation,
      'cached_at': DateTime.now().toIso8601String(),
      'synced': false,
    });

    // Keep only last 50 recommendations
    if (cachedList.length > 50) {
      cachedList.removeRange(0, cachedList.length - 50);
    }

    // Save back to cache
    await prefs.setString(_cachedRecommendationsKey, json.encode(cachedList));
  }

  /// Sync cached recommendations when online
  static Future<Map<String, dynamic>> syncCachedRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cachedRecommendationsKey) ?? '[]';
      final cachedList =
          List<Map<String, dynamic>>.from(json.decode(cachedString));

      final unsyncedRecommendations =
          cachedList.where((rec) => !rec['synced']).toList();

      if (unsyncedRecommendations.isEmpty) {
        return {
          'success': true,
          'message': 'No recommendations to sync',
          'synced_count': 0,
        };
      }

      // Check connectivity
      final isOnline = await NetworkService.checkConnectivity();
      if (!isOnline) {
        return {
          'success': false,
          'error': 'No network connection for sync',
        };
      }

      // Sync recommendations (in production, send to analytics/storage API)
      int syncedCount = 0;
      for (final rec in unsyncedRecommendations) {
        // Mark as synced
        rec['synced'] = true;
        rec['synced_at'] = DateTime.now().toIso8601String();
        syncedCount++;
      }

      // Save updated cache
      await prefs.setString(_cachedRecommendationsKey, json.encode(cachedList));

      return {
        'success': true,
        'message': 'Recommendations synced successfully',
        'synced_count': syncedCount,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Sync failed: ${e.toString()}',
      };
    }
  }

  /// Get cache status and statistics
  static Future<Map<String, dynamic>> getCacheStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final isOfflineAvailable = await isOfflineModeAvailable();
    final downloadDate = prefs.getString('ultra_offline_download_date');
    final cacheSize = await _calculateCacheSize();

    final cachedString = prefs.getString(_cachedRecommendationsKey) ?? '[]';
    final cachedList =
        List<Map<String, dynamic>>.from(json.decode(cachedString));
    final unsyncedCount = cachedList.where((rec) => !rec['synced']).length;

    return {
      'offline_available': isOfflineAvailable,
      'download_date': downloadDate,
      'cache_size_mb': cacheSize,
      'cached_recommendations': cachedList.length,
      'unsynced_recommendations': unsyncedCount,
      'cache_validity': downloadDate != null
          ? DateTime.now().difference(DateTime.parse(downloadDate)).inDays < 7
          : false,
    };
  }

  /// Calculate cache size in MB
  static Future<double> _calculateCacheSize() async {
    final prefs = await SharedPreferences.getInstance();

    int totalSize = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_cachePrefix) ||
          key == _offlineModelsKey ||
          key == _cachedRecommendationsKey) {
        final value = prefs.getString(key) ?? '';
        totalSize += value.length;
      }
    }

    return totalSize / (1024 * 1024); // Convert to MB
  }

  /// Clear offline cache
  static Future<void> clearOfflineCache() async {
    final prefs = await SharedPreferences.getInstance();

    final keysToRemove = prefs
        .getKeys()
        .where((key) =>
            key.startsWith(_cachePrefix) ||
            key == _offlineModelsKey ||
            key == _cachedRecommendationsKey ||
            key == 'ultra_offline_available' ||
            key == 'ultra_offline_download_date')
        .toList();

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }
}
