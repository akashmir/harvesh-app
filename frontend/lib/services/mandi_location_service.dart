import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'agmarknet_service.dart';
import 'location_service.dart';

/// Service for finding nearest mandis and managing location-based market data
class MandiLocationService {
  static const double _maxSearchRadius = 100.0; // Maximum search radius in km
  static const int _maxMandis = 10; // Maximum number of mandis to return

  /// Get nearest mandis to user's current location
  static Future<Map<String, dynamic>>
      getNearestMandisToCurrentLocation() async {
    try {
      // Get user's current location
      final position = await LocationService.getCurrentLocation();

      if (position == null) {
        return {
          'success': false,
          'error':
              'Unable to get current location. Please check location permissions.',
          'data': []
        };
      }

      return await getNearestMandisToPosition(
          position.latitude, position.longitude);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting nearest mandis to current location: $e');
      }
      return {
        'success': false,
        'error': 'Failed to get location: ${e.toString()}',
        'data': []
      };
    }
  }

  /// Get nearest mandis to specific coordinates
  static Future<Map<String, dynamic>> getNearestMandisToPosition(
      double latitude, double longitude) async {
    try {
      final nearestMandis = await AgmarknetService.getNearestMandis(
              latitude, longitude,
              limit: _maxMandis)
          .timeout(const Duration(seconds: 5));

      if (nearestMandis.isEmpty) {
        return {
          'success': false,
          'error': 'No mandis found within ${_maxSearchRadius}km radius',
          'data': []
        };
      }

      // Filter mandis within search radius
      final nearbyMandis = nearestMandis
          .where((mandi) => mandi['distance_km'] <= _maxSearchRadius)
          .toList();

      if (nearbyMandis.isEmpty) {
        return {
          'success': false,
          'error': 'No mandis found within ${_maxSearchRadius}km radius',
          'data': []
        };
      }

      return {
        'success': true,
        'data': nearbyMandis,
        'user_location': {'latitude': latitude, 'longitude': longitude},
        'search_radius_km': _maxSearchRadius,
        'total_found': nearbyMandis.length
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting nearest mandis to position: $e');
      }

      // No mandis found - return empty data
      return {
        'success': true,
        'data': [],
        'user_location': {'latitude': latitude, 'longitude': longitude},
        'search_radius_km': _maxSearchRadius,
        'total_found': 0,
        'fallback': true,
        'message': 'No mandis found near your location'
      };
    }
  }

  /// Generate fallback mandi data when API is unavailable
  static List<Map<String, dynamic>> _generateFallbackMandis(
      double latitude, double longitude) {
    return [
      {
        'mandi_name': 'Sample Mandi 1',
        'state': 'Sample State',
        'district': 'Sample District',
        'latitude': latitude + 0.01,
        'longitude': longitude + 0.01,
        'distance_km': 5.0,
        'crops_available': ['Rice', 'Wheat', 'Maize', 'Cotton', 'Tomato']
      },
      {
        'mandi_name': 'Sample Mandi 2',
        'state': 'Sample State',
        'district': 'Sample District',
        'latitude': latitude - 0.01,
        'longitude': longitude + 0.01,
        'distance_km': 8.0,
        'crops_available': ['Wheat', 'Rice', 'Sugarcane', 'Potato']
      },
      {
        'mandi_name': 'Sample Mandi 3',
        'state': 'Sample State',
        'district': 'Sample District',
        'latitude': latitude + 0.01,
        'longitude': longitude - 0.01,
        'distance_km': 12.0,
        'crops_available': ['Cotton', 'Soybean', 'Wheat', 'Rice']
      }
    ];
  }

  /// Get market prices from nearest mandis
  static Future<Map<String, dynamic>> getLocationBasedMarketPrices() async {
    try {
      final position = await LocationService.getCurrentLocation();

      if (position == null) {
        return {
          'success': false,
          'error':
              'Unable to get current location. Please check location permissions.',
          'data': []
        };
      }

      // Add timeout to the entire operation
      return await AgmarknetService.getLocationBasedPrices(
              position.latitude, position.longitude)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location-based market prices: $e');
      }

      // If timeout or other error, return empty data
      return {
        'success': true,
        'data': [],
        'fallback': true,
        'message': 'No mandis found near your location'
      };
    }
  }

  /// Generate fallback prices when API is unavailable
  static List<Map<String, dynamic>> _generateFallbackPrices(
      double latitude, double longitude) {
    final basePrices = {
      'Rice': {'min': 20.0, 'max': 35.0, 'unit': 'kg'},
      'Wheat': {'min': 18.0, 'max': 28.0, 'unit': 'kg'},
      'Maize': {'min': 15.0, 'max': 25.0, 'unit': 'kg'},
      'Cotton': {'min': 55.0, 'max': 80.0, 'unit': 'kg'},
      'Tomato': {'min': 25.0, 'max': 50.0, 'unit': 'kg'},
    };

    List<Map<String, dynamic>> prices = [];

    basePrices.forEach((crop, priceData) {
      final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
      final price = (priceData['min'] as double) +
          ((priceData['max'] as double) - (priceData['min'] as double)) *
              random;

      prices.add({
        'crop_name': crop,
        'current_price': price.toStringAsFixed(2),
        'unit': priceData['unit'],
        'price_type': 'wholesale',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': _getMarketDemand(
            price, priceData['min'] as double, priceData['max'] as double),
        'mandi_name': 'Sample Mandi',
        'mandi_distance': 5.0,
        'mandi_state': 'Sample State',
        'mandi_district': 'Sample District',
      });
    });

    return prices;
  }

  static String _getMarketDemand(double price, double min, double max) {
    final range = max - min;
    final position = (price - min) / range;

    if (position < 0.3) return 'Low';
    if (position < 0.7) return 'Medium';
    return 'High';
  }

  /// Get market prices for a specific mandi
  static Future<Map<String, dynamic>> getMandiPrices(String mandiName) async {
    try {
      final prices = await AgmarknetService.getMandiPrices(mandiName);

      return {
        'success': true,
        'data': prices,
        'mandi_name': mandiName,
        'total_crops': prices.length
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting prices for mandi $mandiName: $e');
      }
      return {
        'success': false,
        'error': 'Failed to get prices for $mandiName: ${e.toString()}',
        'data': []
      };
    }
  }

  /// Get mandis by state
  static Future<Map<String, dynamic>> getMandisByState(String state) async {
    try {
      final mandis = await AgmarknetService.getMandisByState(state);

      return {
        'success': true,
        'data': mandis,
        'state': state,
        'total_mandis': mandis.length
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting mandis for state $state: $e');
      }
      return {
        'success': false,
        'error': 'Failed to get mandis for $state: ${e.toString()}',
        'data': []
      };
    }
  }

  /// Search mandis by name or location
  static Future<Map<String, dynamic>> searchMandis(String query) async {
    try {
      if (query.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Search query cannot be empty',
          'data': []
        };
      }

      final mandis = await AgmarknetService.searchMandis(query);

      return {
        'success': true,
        'data': mandis,
        'query': query,
        'total_found': mandis.length
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error searching mandis: $e');
      }
      return {
        'success': false,
        'error': 'Failed to search mandis: ${e.toString()}',
        'data': []
      };
    }
  }

  /// Get available states with mandis
  static List<String> getAvailableStates() {
    return AgmarknetService.getAvailableStates();
  }

  /// Get location status and nearest mandi info
  static Future<Map<String, dynamic>> getLocationAndMandiStatus() async {
    try {
      final locationStatus = await LocationService.getLocationStatus();
      final nearestMandis = await getNearestMandisToCurrentLocation();

      return {
        'location_status': locationStatus,
        'nearest_mandis': nearestMandis,
        'available_states': getAvailableStates(),
        'timestamp': DateTime.now().toIso8601String()
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location and mandi status: $e');
      }
      return {
        'error': e.toString(),
        'location_status': {'error': 'Failed to get location status'},
        'nearest_mandis': {'success': false, 'error': 'Failed to get mandis'},
        'available_states': [],
        'timestamp': DateTime.now().toIso8601String()
      };
    }
  }

  /// Check if location services are available and working
  static Future<bool> isLocationServiceAvailable() async {
    try {
      final serviceEnabled = await LocationService.isLocationServiceEnabled();
      final permission = await LocationService.checkLocationPermission();

      return serviceEnabled &&
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location service availability: $e');
      }
      return false;
    }
  }

  /// Request location permission and get nearest mandis
  static Future<Map<String, dynamic>> requestLocationAndGetMandis() async {
    try {
      // Request location permission
      final permission = await LocationService.requestLocationPermission();

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return {
          'success': false,
          'error':
              'Location permission denied. Please enable location access to find nearby mandis.',
          'permission_status': permission.toString(),
          'data': []
        };
      }

      // Get nearest mandis
      return await getNearestMandisToCurrentLocation();
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting location and getting mandis: $e');
      }
      return {
        'success': false,
        'error': 'Failed to get location and mandis: ${e.toString()}',
        'data': []
      };
    }
  }
}
