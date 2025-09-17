import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration management for all API endpoints and settings
class AppConfig {
  // Environment variables with fallbacks
  static String get _weatherApiKey =>
      dotenv.env['WEATHER_API_KEY'] ?? '8382d6ea94ce19069453dc3ffb5e8518';

  static String get _cropApiBaseUrl =>
      dotenv.env['CROP_API_BASE_URL'] ??
      'https://crop-recommendation-api-273619012635.us-central1.run.app';

  static String get _cropCalendarApiBaseUrl {
    // Try environment variable first
    if (dotenv.env['CROP_CALENDAR_API_BASE_URL'] != null) {
      return dotenv.env['CROP_CALENDAR_API_BASE_URL']!;
    }

    // For Android emulator, use 10.0.2.2 (emulator's localhost)
    // For physical device, use your computer's IP address
    // For web/desktop, use localhost
    return 'http://10.0.2.2:5001';
  }

  // Field Management API Base URL
  static String get _fieldManagementApiBaseUrl {
    // Try environment variable first
    if (dotenv.env['FIELD_MANAGEMENT_API_BASE_URL'] != null) {
      return dotenv.env['FIELD_MANAGEMENT_API_BASE_URL']!;
    }

    // For Android emulator, use 10.0.2.2 (emulator's localhost)
    // For physical device, use your computer's IP address
    // For web/desktop, use localhost
    return 'http://10.0.2.2:5002';
  }

  // Yield Prediction API Base URL
  static String get _yieldPredictionApiBaseUrl {
    // Try environment variable first
    if (dotenv.env['YIELD_PREDICTION_API_BASE_URL'] != null) {
      return dotenv.env['YIELD_PREDICTION_API_BASE_URL']!;
    }

    // For Android emulator, use 10.0.2.2 (emulator's localhost)
    // For physical device, use your computer's IP address
    // For web/desktop, use localhost
    return 'http://10.0.2.2:5003';
  }

  // Market Price API Base URL
  static String get _marketPriceApiBaseUrl {
    // Try environment variable first
    if (dotenv.env['MARKET_PRICE_API_BASE_URL'] != null) {
      return dotenv.env['MARKET_PRICE_API_BASE_URL']!;
    }

    // Google Cloud Run URL - deployed market price API
    // For local development, use 10.0.2.2 (emulator's localhost)
    // For production, use the Google Cloud Run URL
    return 'https://market-price-api-273619012635.us-central1.run.app';
  }

  static String get _firebaseApiKey =>
      dotenv.env['FIREBASE_API_KEY'] ??
      'AIzaSyA2jnSHh16PjgcDOymvfRUfQNZt41U7VMk';

  static String get _firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? 'agrismart-app-1930c';

  static String get _firebaseAppId =>
      dotenv.env['FIREBASE_APP_ID'] ??
      '1:273619012635:android:404c0b4e3786f0f1047cbe';

  static String get _firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '273619012635';

  static String get _firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ??
      'agrismart-app-1930c.firebasestorage.app';

  // API Configuration
  static String get _apiTimeout => dotenv.env['API_TIMEOUT'] ?? '30';
  static String get _apiRetryCount => dotenv.env['API_RETRY_COUNT'] ?? '3';
  static String get _apiRetryDelay => dotenv.env['API_RETRY_DELAY'] ?? '2000';

  // App Configuration
  static String get _appName => dotenv.env['APP_NAME'] ?? 'Harvest';
  static String get _appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get _debugMode => dotenv.env['DEBUG_MODE'] ?? 'false';

  // Public Getters
  static String get weatherApiKey => _weatherApiKey;
  static String get cropApiBaseUrl => _cropApiBaseUrl;
  static String get cropCalendarApiBaseUrl => _cropCalendarApiBaseUrl;
  static String get firebaseApiKey => _firebaseApiKey;
  static String get firebaseProjectId => _firebaseProjectId;
  static String get firebaseAppId => _firebaseAppId;
  static String get firebaseMessagingSenderId => _firebaseMessagingSenderId;
  static String get firebaseStorageBucket => _firebaseStorageBucket;
  static String get appName => _appName;
  static String get appVersion => _appVersion;
  static bool get debugMode => _debugMode.toLowerCase() == 'true';

  // API Configuration
  static Duration get apiTimeout =>
      Duration(seconds: int.tryParse(_apiTimeout) ?? 30);
  static int get apiRetryCount => int.tryParse(_apiRetryCount) ?? 3;
  static Duration get apiRetryDelay =>
      Duration(milliseconds: int.tryParse(_apiRetryDelay) ?? 2000);

  // API Endpoints
  static String get cropRecommendationEndpoint => '$cropApiBaseUrl/recommend';
  static String get cropHealthEndpoint => '$cropApiBaseUrl/health';
  static String get cropCropsEndpoint => '$cropApiBaseUrl/crops';
  static String get cropFeaturesEndpoint => '$cropApiBaseUrl/features';
  static String get cropPerformanceEndpoint => '$cropApiBaseUrl/performance';
  static String get cropCacheEndpoint => '$cropApiBaseUrl/cache/clear';

  // Crop Calendar API Endpoints
  static String get cropCalendarHealthEndpoint =>
      '$cropCalendarApiBaseUrl/health';
  static String get cropCalendarCropEndpoint =>
      '$cropCalendarApiBaseUrl/calendar/crop';
  static String get cropCalendarMonthEndpoint =>
      '$cropCalendarApiBaseUrl/calendar/month';
  static String get cropCalendarSeasonEndpoint =>
      '$cropCalendarApiBaseUrl/calendar/season';
  static String get cropCalendarYearlyEndpoint =>
      '$cropCalendarApiBaseUrl/calendar/yearly';
  static String get cropCalendarCurrentEndpoint =>
      '$cropCalendarApiBaseUrl/calendar/current';
  static String get cropCalendarCropsEndpoint =>
      '$cropCalendarApiBaseUrl/calendar/crops';
  static String get cropCalendarSeasonsEndpoint =>
      '$cropCalendarApiBaseUrl/calendar/seasons';

  // Field Management API Endpoints
  static String get fieldManagementApiBaseUrl => _fieldManagementApiBaseUrl;
  static String get fieldManagementHealthEndpoint =>
      '$fieldManagementApiBaseUrl/health';
  static String get fieldManagementFieldsEndpoint =>
      '$fieldManagementApiBaseUrl/fields';
  static String get fieldManagementFieldEndpoint =>
      '$fieldManagementApiBaseUrl/fields';
  static String get fieldManagementNearbyFieldsEndpoint =>
      '$fieldManagementApiBaseUrl/fields/nearby';
  static String get fieldManagementSoilTypesEndpoint =>
      '$fieldManagementApiBaseUrl/soil-types';
  static String get fieldManagementFieldRecommendationsEndpoint =>
      '$fieldManagementApiBaseUrl/fields';

  // Yield Prediction API Endpoints
  static String get yieldPredictionApiBaseUrl => _yieldPredictionApiBaseUrl;
  static String get yieldPredictionHealthEndpoint =>
      '$yieldPredictionApiBaseUrl/health';
  static String get yieldPredictionPredictEndpoint =>
      '$yieldPredictionApiBaseUrl/predict';
  static String get yieldPredictionCropsEndpoint =>
      '$yieldPredictionApiBaseUrl/crops';
  static String get yieldPredictionHistoricalEndpoint =>
      '$yieldPredictionApiBaseUrl/historical';
  static String get yieldPredictionAnalyticsEndpoint =>
      '$yieldPredictionApiBaseUrl/analytics';
  static String get yieldPredictionPredictionsEndpoint =>
      '$yieldPredictionApiBaseUrl/predictions';
  static String get yieldPredictionFactorsEndpoint =>
      '$yieldPredictionApiBaseUrl/factors';

  // Market Price API Endpoints
  static String get marketPriceApiBaseUrl => _marketPriceApiBaseUrl;
  static String get marketPriceHealthEndpoint =>
      '$marketPriceApiBaseUrl/health';
  static String get marketPriceCurrentEndpoint =>
      '$marketPriceApiBaseUrl/price/current';
  static String get marketPricePredictEndpoint =>
      '$marketPriceApiBaseUrl/price/predict';
  static String get marketPriceCalculateEndpoint =>
      '$marketPriceApiBaseUrl/profit/calculate';
  static String get marketPriceCropsEndpoint => '$marketPriceApiBaseUrl/crops';
  static String get marketPriceHistoryEndpoint =>
      '$marketPriceApiBaseUrl/prices/history';
  static String get marketPriceAnalyticsEndpoint =>
      '$marketPriceApiBaseUrl/analytics';

  // Weather Integration API Base URL
  static String get _weatherIntegrationApiBaseUrl {
    // Try environment variable first
    if (dotenv.env['WEATHER_INTEGRATION_API_BASE_URL'] != null) {
      return dotenv.env['WEATHER_INTEGRATION_API_BASE_URL']!;
    }

    // For Android emulator, use 10.0.2.2 (emulator's localhost)
    // For physical device, use your computer's IP address
    // For web/desktop, use localhost
    return 'http://10.0.2.2:5005';
  }

  // Weather Integration API Endpoints
  static String get weatherIntegrationApiBaseUrl =>
      _weatherIntegrationApiBaseUrl;
  static String get weatherIntegrationHealthEndpoint =>
      '$weatherIntegrationApiBaseUrl/health';
  static String get weatherIntegrationCurrentEndpoint =>
      '$weatherIntegrationApiBaseUrl/weather/current';
  static String get weatherIntegrationForecastEndpoint =>
      '$weatherIntegrationApiBaseUrl/weather/forecast';
  static String get weatherIntegrationRecommendationsEndpoint =>
      '$weatherIntegrationApiBaseUrl/weather/recommendations';
  static String get weatherIntegrationAlertsEndpoint =>
      '$weatherIntegrationApiBaseUrl/weather/alerts';
  static String get weatherIntegrationHistoryEndpoint =>
      '$weatherIntegrationApiBaseUrl/weather/history';
  static String get weatherIntegrationAnalyticsEndpoint =>
      '$weatherIntegrationApiBaseUrl/weather/analytics';

  // Additional Features Enhanced APIs Configuration

  // Ultra Crop Recommender API Base URL
  static String get baseUrl {
    final envUrl = dotenv.env['ULTRA_CROP_API_BASE_URL'];
    print('AppConfig: ULTRA_CROP_API_BASE_URL from env: $envUrl');

    if (envUrl != null) {
      print('AppConfig: Using environment URL: $envUrl');
      return envUrl;
    }

    // Default production URL - using the deployed ultra crop recommender API
    final defaultUrl =
        'https://ultra-crop-recommender-api-psicxu7eya-uc.a.run.app';
    print('AppConfig: Using default URL: $defaultUrl');
    return defaultUrl;
  }

  // Satellite Soil API Base URL
  static String get _satelliteSoilApiBaseUrl {
    if (dotenv.env['SATELLITE_SOIL_API_BASE_URL'] != null) {
      return dotenv.env['SATELLITE_SOIL_API_BASE_URL']!;
    }
    return 'https://sih2025-soil-api-psicxu7eya-uc.a.run.app';
  }

  // Multilingual AI API Base URL
  static String get _multilingualAiApiBaseUrl {
    if (dotenv.env['MULTILINGUAL_AI_API_BASE_URL'] != null) {
      return dotenv.env['MULTILINGUAL_AI_API_BASE_URL']!;
    }
    return 'https://sih2025-multilingual-api-psicxu7eya-uc.a.run.app';
  }

  // Disease Detection API Base URL
  static String get _diseaseDetectionApiBaseUrl {
    if (dotenv.env['DISEASE_DETECTION_API_BASE_URL'] != null) {
      return dotenv.env['DISEASE_DETECTION_API_BASE_URL']!;
    }
    return 'https://sih2025-disease-api-psicxu7eya-uc.a.run.app';
  }

  // Sustainability Scoring API Base URL
  static String get _sustainabilityScoringApiBaseUrl {
    if (dotenv.env['SUSTAINABILITY_SCORING_API_BASE_URL'] != null) {
      return dotenv.env['SUSTAINABILITY_SCORING_API_BASE_URL']!;
    }
    return 'https://sih2025-sustainability-api-psicxu7eya-uc.a.run.app';
  }

  // Crop Rotation API Base URL
  static String get _cropRotationApiBaseUrl {
    if (dotenv.env['CROP_ROTATION_API_BASE_URL'] != null) {
      return dotenv.env['CROP_ROTATION_API_BASE_URL']!;
    }
    return 'https://sih2025-rotation-api-psicxu7eya-uc.a.run.app';
  }

  // Offline Capability API Base URL
  static String get _offlineCapabilityApiBaseUrl {
    if (dotenv.env['OFFLINE_CAPABILITY_API_BASE_URL'] != null) {
      return dotenv.env['OFFLINE_CAPABILITY_API_BASE_URL']!;
    }
    return 'https://sih2025-offline-api-psicxu7eya-uc.a.run.app';
  }

  // Integrated Additional Features API Base URL
  static String get _sih2025IntegratedApiBaseUrl {
    if (dotenv.env['SIH_2025_INTEGRATED_API_BASE_URL'] != null) {
      return dotenv.env['SIH_2025_INTEGRATED_API_BASE_URL']!;
    }
    return 'https://sih2025-integrated-api-psicxu7eya-uc.a.run.app';
  }

  // Satellite Soil API Endpoints
  static String get satelliteSoilApiBaseUrl => _satelliteSoilApiBaseUrl;
  static String get satelliteSoilHealthEndpoint =>
      '$satelliteSoilApiBaseUrl/health';
  static String get satelliteSoilCurrentEndpoint =>
      '$satelliteSoilApiBaseUrl/soil/current';
  static String get satelliteSoilHistoricalEndpoint =>
      '$satelliteSoilApiBaseUrl/soil/historical';
  static String get satelliteSoilRecommendationsEndpoint =>
      '$satelliteSoilApiBaseUrl/soil/recommendations';
  static String get satelliteSoilHealthAnalysisEndpoint =>
      '$satelliteSoilApiBaseUrl/soil/health-analysis';

  // Multilingual AI API Endpoints
  static String get multilingualAiApiBaseUrl => _multilingualAiApiBaseUrl;
  static String get multilingualAiHealthEndpoint =>
      '$multilingualAiApiBaseUrl/health';
  static String get multilingualAiChatEndpoint =>
      '$multilingualAiApiBaseUrl/chat';
  static String get multilingualAiVoiceEndpoint =>
      '$multilingualAiApiBaseUrl/voice';
  static String get multilingualAiLanguagesEndpoint =>
      '$multilingualAiApiBaseUrl/languages';
  static String get multilingualAiTranslateEndpoint =>
      '$multilingualAiApiBaseUrl/translate';

  // Disease Detection API Endpoints
  static String get diseaseDetectionApiBaseUrl => _diseaseDetectionApiBaseUrl;
  static String get diseaseDetectionHealthEndpoint =>
      '$diseaseDetectionApiBaseUrl/health';
  static String get diseaseDetectionAnalyzeEndpoint =>
      '$diseaseDetectionApiBaseUrl/detect/analyze';
  static String get diseaseDetectionDiseasesEndpoint =>
      '$diseaseDetectionApiBaseUrl/diseases';
  static String get diseaseDetectionPestsEndpoint =>
      '$diseaseDetectionApiBaseUrl/pests';
  static String get diseaseDetectionTreatmentEndpoint =>
      '$diseaseDetectionApiBaseUrl/treatment';

  // Sustainability Scoring API Endpoints
  static String get sustainabilityScoringApiBaseUrl =>
      _sustainabilityScoringApiBaseUrl;
  static String get sustainabilityScoringHealthEndpoint =>
      '$sustainabilityScoringApiBaseUrl/health';
  static String get sustainabilityScoringCalculateEndpoint =>
      '$sustainabilityScoringApiBaseUrl/sustainability/calculate';
  static String get sustainabilityScoringRecommendationsEndpoint =>
      '$sustainabilityScoringApiBaseUrl/sustainability/recommendations';
  static String get sustainabilityScoringCarbonFootprintEndpoint =>
      '$sustainabilityScoringApiBaseUrl/sustainability/carbon-footprint';

  // Crop Rotation API Endpoints
  static String get cropRotationApiBaseUrl => _cropRotationApiBaseUrl;
  static String get cropRotationHealthEndpoint =>
      '$cropRotationApiBaseUrl/health';
  static String get cropRotationPlanEndpoint =>
      '$cropRotationApiBaseUrl/rotation/plan';
  static String get cropRotationRecommendationsEndpoint =>
      '$cropRotationApiBaseUrl/rotation/recommendations';
  static String get cropRotationHistoryEndpoint =>
      '$cropRotationApiBaseUrl/rotation/history';

  // Offline Capability API Endpoints
  static String get offlineCapabilityApiBaseUrl => _offlineCapabilityApiBaseUrl;
  static String get offlineCapabilityHealthEndpoint =>
      '$offlineCapabilityApiBaseUrl/health';
  static String get offlineCapabilityStatusEndpoint =>
      '$offlineCapabilityApiBaseUrl/offline/status';
  static String get offlineCapabilitySyncEndpoint =>
      '$offlineCapabilityApiBaseUrl/offline/sync';
  static String get offlineCapabilityDataEndpoint =>
      '$offlineCapabilityApiBaseUrl/offline/data';

  // Integrated Additional Features API Endpoints
  static String get sih2025IntegratedApiBaseUrl => _sih2025IntegratedApiBaseUrl;
  static String get sih2025IntegratedHealthEndpoint =>
      '$sih2025IntegratedApiBaseUrl/health';
  static String get sih2025IntegratedRecommendEndpoint =>
      '$sih2025IntegratedApiBaseUrl/recommend';
  static String get sih2025IntegratedComprehensiveEndpoint =>
      '$sih2025IntegratedApiBaseUrl/comprehensive';

  // Weather API Endpoints
  static String get weatherBaseUrl => 'https://api.openweathermap.org/data/2.5';
  static String get weatherCurrentEndpoint => '$weatherBaseUrl/weather';
  static String get weatherForecastEndpoint => '$weatherBaseUrl/forecast';
  static String get weatherIconBaseUrl => 'https://openweathermap.org/img/wn';

  // Blog API Endpoints (if using external blog service)
  static String get blogBaseUrl =>
      dotenv.env['BLOG_API_BASE_URL'] ?? 'https://api.example.com/blogs';
  static String get blogListEndpoint => '$blogBaseUrl/list';
  static String get blogDetailEndpoint => '$blogBaseUrl/detail';

  // Image/Asset URLs
  static String get defaultImageUrl =>
      'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=400';
  static String get placeholderImageUrl =>
      'https://via.placeholder.com/400x300?text=No+Image';

  // Validation
  static bool get isWeatherApiKeyValid =>
      _weatherApiKey.isNotEmpty && _weatherApiKey.length > 10;

  static bool get isFirebaseConfigValid =>
      _firebaseApiKey.isNotEmpty &&
      _firebaseProjectId.isNotEmpty &&
      _firebaseAppId.isNotEmpty;

  static bool get isCropApiUrlValid =>
      _cropApiBaseUrl.isNotEmpty && _cropApiBaseUrl.startsWith('http');

  static bool get isBlogApiUrlValid =>
      blogBaseUrl.isNotEmpty && blogBaseUrl.startsWith('http');

  // Configuration validation
  static Map<String, bool> get configurationStatus => {
        'weatherApi': isWeatherApiKeyValid,
        'cropApi': isCropApiUrlValid,
        'firebase': isFirebaseConfigValid,
        'blogApi': isBlogApiUrlValid,
      };

  // Get all invalid configurations
  static List<String> get invalidConfigurations {
    final List<String> invalid = [];
    if (!isWeatherApiKeyValid) invalid.add('Weather API Key');
    if (!isCropApiUrlValid) invalid.add('Crop API URL');
    if (!isFirebaseConfigValid) invalid.add('Firebase Configuration');
    if (!isBlogApiUrlValid) invalid.add('Blog API URL');
    return invalid;
  }

  // Check if all critical configurations are valid
  static bool get isConfigurationValid =>
      isWeatherApiKeyValid && isCropApiUrlValid && isFirebaseConfigValid;

  // Get configuration summary
  static Map<String, dynamic> get configurationSummary => {
        'appName': appName,
        'appVersion': appVersion,
        'debugMode': debugMode,
        'apiTimeout': apiTimeout.inSeconds,
        'apiRetryCount': apiRetryCount,
        'apiRetryDelay': apiRetryDelay.inMilliseconds,
        'endpoints': {
          'cropApi': cropApiBaseUrl,
          'weatherApi': weatherBaseUrl,
          'blogApi': blogBaseUrl,
        },
        'validation': configurationStatus,
      };
}
