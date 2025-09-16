import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'error_handler.dart';
import 'retry_service.dart';
import 'offline_service.dart';

/// Service for handling network operations with offline support
class NetworkService {
  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// Make HTTP GET request with retry and offline support
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
    bool useOfflineCache = true,
    String? cacheKey,
  }) async {
    try {
      // Check if we should use cached data
      if (useOfflineCache && OfflineService.isOffline && cacheKey != null) {
        final cachedData = await _getCachedData(cacheKey);
        if (cachedData != null) {
          if (kDebugMode) {
            print('Using cached data for: $endpoint');
          }
          return cachedData;
        }
      }

      // Make the request with retry
      final response = await RetryService.retryNetworkOperation(
        () => http
            .get(
              Uri.parse(endpoint),
              headers: _buildHeaders(headers),
            )
            .timeout(timeout ?? _defaultTimeout),
        operationName: 'GET $endpoint',
      );

      final data = _handleResponse(response);

      // Cache the response if offline caching is enabled
      if (useOfflineCache && cacheKey != null) {
        await _cacheData(cacheKey, data);
      }

      return data;
    } catch (error) {
      // If offline and we have cached data, return it
      if (OfflineService.isOffline && useOfflineCache && cacheKey != null) {
        final cachedData = await _getCachedData(cacheKey);
        if (cachedData != null) {
          if (kDebugMode) {
            print('Using cached data due to offline status: $endpoint');
          }
          return cachedData;
        }
      }

      // Re-throw the error
      throw error;
    }
  }

  /// Make HTTP POST request with retry and offline support
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    bool saveForOfflineSync = true,
  }) async {
    try {
      final response = await RetryService.retryApiOperation(
        () => http
            .post(
              Uri.parse(endpoint),
              headers: _buildHeaders(headers),
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout ?? _defaultTimeout),
        operationName: 'POST $endpoint',
      );

      final data = _handleResponse(response);

      // Save for offline sync if enabled and we're offline
      if (saveForOfflineSync && OfflineService.isOffline) {
        await OfflineService.saveForOfflineSync(
          dataType: 'POST_$endpoint',
          data: {
            'endpoint': endpoint,
            'body': body,
            'headers': headers,
            'response': data,
          },
        );
      }

      return data;
    } catch (error) {
      // If offline and saveForOfflineSync is enabled, save the request
      if (OfflineService.isOffline && saveForOfflineSync) {
        await OfflineService.saveForOfflineSync(
          dataType: 'POST_$endpoint',
          data: {
            'endpoint': endpoint,
            'body': body,
            'headers': headers,
            'error': error.toString(),
          },
        );
      }

      // Re-throw the error
      throw error;
    }
  }

  /// Make HTTP PUT request with retry and offline support
  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    bool saveForOfflineSync = true,
  }) async {
    try {
      final response = await RetryService.retryApiOperation(
        () => http
            .put(
              Uri.parse(endpoint),
              headers: _buildHeaders(headers),
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout ?? _defaultTimeout),
        operationName: 'PUT $endpoint',
      );

      final data = _handleResponse(response);

      // Save for offline sync if enabled and we're offline
      if (saveForOfflineSync && OfflineService.isOffline) {
        await OfflineService.saveForOfflineSync(
          dataType: 'PUT_$endpoint',
          data: {
            'endpoint': endpoint,
            'body': body,
            'headers': headers,
            'response': data,
          },
        );
      }

      return data;
    } catch (error) {
      // If offline and saveForOfflineSync is enabled, save the request
      if (OfflineService.isOffline && saveForOfflineSync) {
        await OfflineService.saveForOfflineSync(
          dataType: 'PUT_$endpoint',
          data: {
            'endpoint': endpoint,
            'body': body,
            'headers': headers,
            'error': error.toString(),
          },
        );
      }

      // Re-throw the error
      throw error;
    }
  }

  /// Make HTTP DELETE request with retry and offline support
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
    bool saveForOfflineSync = true,
  }) async {
    try {
      final response = await RetryService.retryApiOperation(
        () => http
            .delete(
              Uri.parse(endpoint),
              headers: _buildHeaders(headers),
            )
            .timeout(timeout ?? _defaultTimeout),
        operationName: 'DELETE $endpoint',
      );

      final data = _handleResponse(response);

      // Save for offline sync if enabled and we're offline
      if (saveForOfflineSync && OfflineService.isOffline) {
        await OfflineService.saveForOfflineSync(
          dataType: 'DELETE_$endpoint',
          data: {
            'endpoint': endpoint,
            'headers': headers,
            'response': data,
          },
        );
      }

      return data;
    } catch (error) {
      // If offline and saveForOfflineSync is enabled, save the request
      if (OfflineService.isOffline && saveForOfflineSync) {
        await OfflineService.saveForOfflineSync(
          dataType: 'DELETE_$endpoint',
          data: {
            'endpoint': endpoint,
            'headers': headers,
            'error': error.toString(),
          },
        );
      }

      // Re-throw the error
      throw error;
    }
  }

  /// Sync offline data when connection is restored
  static Future<void> syncOfflineData() async {
    if (OfflineService.isOffline) return;

    try {
      final pendingData = await OfflineService.getPendingSyncData();

      for (final data in pendingData) {
        try {
          final dataType = data['dataType'] as String;
          final requestData = data['data'] as Map<String, dynamic>;

          if (dataType.startsWith('POST_')) {
            await post(
              requestData['endpoint'],
              body: requestData['body'],
              headers: Map<String, String>.from(requestData['headers'] ?? {}),
              saveForOfflineSync: false,
            );
          } else if (dataType.startsWith('PUT_')) {
            await put(
              requestData['endpoint'],
              body: requestData['body'],
              headers: Map<String, String>.from(requestData['headers'] ?? {}),
              saveForOfflineSync: false,
            );
          } else if (dataType.startsWith('DELETE_')) {
            await delete(
              requestData['endpoint'],
              headers: Map<String, String>.from(requestData['headers'] ?? {}),
              saveForOfflineSync: false,
            );
          }

          // Mark as synced
          await OfflineService.markDataAsSynced(data['timestamp']);

          if (kDebugMode) {
            print('Synced offline data: $dataType');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error syncing offline data: $e');
          }
        }
      }

      // Update last sync timestamp
      await OfflineService.setLastSyncTimestamp();

      if (kDebugMode) {
        print('Offline sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during offline sync: $e');
      }
    }
  }

  /// Build headers for requests
  static Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Harvest/${AppConfig.appVersion}',
    };

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ErrorHandler.handleUnknownError('Invalid JSON response: $e');
      }
    } else {
      throw ErrorHandler.handleHttpError(response);
    }
  }

  /// Get cached data
  static Future<Map<String, dynamic>?> _getCachedData(String cacheKey) async {
    try {
      // This would be implemented based on your caching strategy
      // For now, we'll use a simple approach
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached data: $e');
      }
      return null;
    }
  }

  /// Cache data
  static Future<void> _cacheData(
      String cacheKey, Map<String, dynamic> data) async {
    try {
      // This would be implemented based on your caching strategy
      // For now, we'll use a simple approach
    } catch (e) {
      if (kDebugMode) {
        print('Error caching data: $e');
      }
    }
  }

  /// Check network connectivity
  static Future<bool> checkConnectivity() async {
    return OfflineService.isOnline;
  }

  /// Get network status
  static Future<Map<String, dynamic>> getNetworkStatus() async {
    return {
      'isOnline': OfflineService.isOnline,
      'connectivityStatus': OfflineService.connectivityStatus?.toString(),
      'lastSync': await OfflineService.getLastSyncTimestamp(),
      'needsSync': await OfflineService.needsSync(),
    };
  }
}
