import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for handling offline functionality and data caching
class OfflineService {
  static const String _cropRecommendationsKey = 'crop_recommendations';
  static const String _weatherDataKey = 'weather_data';
  static const String _userProfileKey = 'user_profile';
  static const String _appSettingsKey = 'app_settings';
  static const String _lastSyncKey = 'last_sync';
  static const String _offlineDataKey = 'offline_data';

  static SharedPreferences? _prefs;
  static ConnectivityResult? _connectivityStatus;

  /// Initialize the offline service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _connectivityStatus = await Connectivity().checkConnectivity();

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _connectivityStatus = result;
      if (kDebugMode) {
        print('Connectivity changed: $result');
      }
    });
  }

  /// Check if device is online
  static bool get isOnline => _connectivityStatus != ConnectivityResult.none;

  /// Check if device is offline
  static bool get isOffline => !isOnline;

  /// Get connectivity status
  static ConnectivityResult? get connectivityStatus => _connectivityStatus;

  /// Cache crop recommendation data
  static Future<void> cacheCropRecommendation({
    required Map<String, dynamic> inputData,
    required Map<String, dynamic> recommendationData,
    required String modelType,
  }) async {
    if (_prefs == null) return;

    try {
      final cacheData = {
        'inputData': inputData,
        'recommendationData': recommendationData,
        'modelType': modelType,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final existingData = _prefs!.getStringList(_cropRecommendationsKey) ?? [];
      existingData.add(jsonEncode(cacheData));

      // Keep only last 50 recommendations
      if (existingData.length > 50) {
        existingData.removeRange(0, existingData.length - 50);
      }

      await _prefs!.setStringList(_cropRecommendationsKey, existingData);

      if (kDebugMode) {
        print('Cached crop recommendation: ${cacheData['id']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching crop recommendation: $e');
      }
    }
  }

  /// Get cached crop recommendations
  static Future<List<Map<String, dynamic>>>
      getCachedCropRecommendations() async {
    if (_prefs == null) return [];

    try {
      final cachedData = _prefs!.getStringList(_cropRecommendationsKey) ?? [];
      return cachedData
          .map((data) => jsonDecode(data) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached crop recommendations: $e');
      }
      return [];
    }
  }

  /// Cache weather data
  static Future<void> cacheWeatherData({
    required String location,
    required Map<String, dynamic> weatherData,
  }) async {
    if (_prefs == null) return;

    try {
      final cacheData = {
        'location': location,
        'weatherData': weatherData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs!
          .setString('${_weatherDataKey}_$location', jsonEncode(cacheData));

      if (kDebugMode) {
        print('Cached weather data for: $location');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching weather data: $e');
      }
    }
  }

  /// Get cached weather data
  static Future<Map<String, dynamic>?> getCachedWeatherData(
      String location) async {
    if (_prefs == null) return null;

    try {
      final cachedData = _prefs!.getString('${_weatherDataKey}_$location');
      if (cachedData != null) {
        final data = jsonDecode(cachedData) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp']);

        // Return cached data if it's less than 30 minutes old
        if (DateTime.now().difference(timestamp).inMinutes < 30) {
          return data;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached weather data: $e');
      }
      return null;
    }
  }

  /// Cache user profile data
  static Future<void> cacheUserProfile(Map<String, dynamic> profileData) async {
    if (_prefs == null) return;

    try {
      await _prefs!.setString(_userProfileKey, jsonEncode(profileData));

      if (kDebugMode) {
        print('Cached user profile data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching user profile: $e');
      }
    }
  }

  /// Get cached user profile
  static Future<Map<String, dynamic>?> getCachedUserProfile() async {
    if (_prefs == null) return null;

    try {
      final cachedData = _prefs!.getString(_userProfileKey);
      if (cachedData != null) {
        return jsonDecode(cachedData) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached user profile: $e');
      }
      return null;
    }
  }

  /// Cache app settings
  static Future<void> cacheAppSettings(Map<String, dynamic> settings) async {
    if (_prefs == null) return;

    try {
      await _prefs!.setString(_appSettingsKey, jsonEncode(settings));

      if (kDebugMode) {
        print('Cached app settings');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching app settings: $e');
      }
    }
  }

  /// Get cached app settings
  static Future<Map<String, dynamic>?> getCachedAppSettings() async {
    if (_prefs == null) return null;

    try {
      final cachedData = _prefs!.getString(_appSettingsKey);
      if (cachedData != null) {
        return jsonDecode(cachedData) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached app settings: $e');
      }
      return null;
    }
  }

  /// Save data for offline sync
  static Future<void> saveForOfflineSync({
    required String dataType,
    required Map<String, dynamic> data,
  }) async {
    if (_prefs == null) return;

    try {
      final offlineData = {
        'dataType': dataType,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
      };

      final existingData = _prefs!.getStringList(_offlineDataKey) ?? [];
      existingData.add(jsonEncode(offlineData));

      await _prefs!.setStringList(_offlineDataKey, existingData);

      if (kDebugMode) {
        print('Saved data for offline sync: $dataType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving data for offline sync: $e');
      }
    }
  }

  /// Get data pending sync
  static Future<List<Map<String, dynamic>>> getPendingSyncData() async {
    if (_prefs == null) return [];

    try {
      final pendingData = _prefs!.getStringList(_offlineDataKey) ?? [];
      return pendingData
          .map((data) => jsonDecode(data) as Map<String, dynamic>)
          .where((data) => data['synced'] == false)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending sync data: $e');
      }
      return [];
    }
  }

  /// Mark data as synced
  static Future<void> markDataAsSynced(String dataId) async {
    if (_prefs == null) return;

    try {
      final pendingData = _prefs!.getStringList(_offlineDataKey) ?? [];
      final updatedData = pendingData.map((data) {
        final parsed = jsonDecode(data) as Map<String, dynamic>;
        if (parsed['timestamp'] == dataId) {
          parsed['synced'] = true;
        }
        return jsonEncode(parsed);
      }).toList();

      await _prefs!.setStringList(_offlineDataKey, updatedData);

      if (kDebugMode) {
        print('Marked data as synced: $dataId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking data as synced: $e');
      }
    }
  }

  /// Clear old cached data
  static Future<void> clearOldCachedData({int maxAgeInDays = 7}) async {
    if (_prefs == null) return;

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));

      // Clear old crop recommendations
      final cropData = _prefs!.getStringList(_cropRecommendationsKey) ?? [];
      final filteredCropData = cropData.where((data) {
        final parsed = jsonDecode(data) as Map<String, dynamic>;
        final timestamp = DateTime.parse(parsed['timestamp']);
        return timestamp.isAfter(cutoffDate);
      }).toList();

      await _prefs!.setStringList(_cropRecommendationsKey, filteredCropData);

      // Clear old weather data
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('${_weatherDataKey}_')) {
          final weatherData = _prefs!.getString(key);
          if (weatherData != null) {
            final parsed = jsonDecode(weatherData) as Map<String, dynamic>;
            final timestamp = DateTime.parse(parsed['timestamp']);
            if (timestamp.isBefore(cutoffDate)) {
              await _prefs!.remove(key);
            }
          }
        }
      }

      if (kDebugMode) {
        print('Cleared old cached data older than $maxAgeInDays days');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing old cached data: $e');
      }
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStatistics() async {
    if (_prefs == null) return {};

    try {
      final cropData = _prefs!.getStringList(_cropRecommendationsKey) ?? [];
      final pendingSyncData = _prefs!.getStringList(_offlineDataKey) ?? [];

      int weatherCacheCount = 0;
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('${_weatherDataKey}_')) {
          weatherCacheCount++;
        }
      }

      return {
        'cropRecommendations': cropData.length,
        'weatherData': weatherCacheCount,
        'pendingSync': pendingSyncData.length,
        'lastSync': _prefs!.getString(_lastSyncKey),
        'isOnline': isOnline,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cache statistics: $e');
      }
      return {};
    }
  }

  /// Clear all cached data
  static Future<void> clearAllCachedData() async {
    if (_prefs == null) return;

    try {
      await _prefs!.remove(_cropRecommendationsKey);
      await _prefs!.remove(_userProfileKey);
      await _prefs!.remove(_appSettingsKey);
      await _prefs!.remove(_offlineDataKey);
      await _prefs!.remove(_lastSyncKey);

      // Clear weather data
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('${_weatherDataKey}_')) {
          await _prefs!.remove(key);
        }
      }

      if (kDebugMode) {
        print('Cleared all cached data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all cached data: $e');
      }
    }
  }

  /// Set last sync timestamp
  static Future<void> setLastSyncTimestamp() async {
    if (_prefs == null) return;

    try {
      await _prefs!.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('Error setting last sync timestamp: $e');
      }
    }
  }

  /// Get last sync timestamp
  static Future<DateTime?> getLastSyncTimestamp() async {
    if (_prefs == null) return null;

    try {
      final timestamp = _prefs!.getString(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last sync timestamp: $e');
      }
      return null;
    }
  }

  /// Check if data needs sync
  static Future<bool> needsSync(
      {Duration maxAge = const Duration(hours: 1)}) async {
    final lastSync = await getLastSyncTimestamp();
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > maxAge;
  }
}
