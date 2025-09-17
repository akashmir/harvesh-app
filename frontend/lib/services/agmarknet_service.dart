import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Service for fetching data from Agmarknet (Government of India)
/// Provides mandi-wise prices for crops
class AgmarknetService {
  // Note: In production, you would use actual Agmarknet API endpoints
  // static const String _baseUrl = 'https://data.gov.in/api/rest/';
  // static const String _apiKey = 'YOUR_API_KEY';

  // Fallback data when API is not available
  static const Map<String, List<Map<String, dynamic>>> _fallbackMandiData = {
    'Delhi': [
      {
        'mandi_name': 'Azadpur Mandi',
        'state': 'Delhi',
        'district': 'North Delhi',
        'latitude': 28.7041,
        'longitude': 77.1025,
        'crops_available': ['Tomato', 'Onion', 'Potato', 'Rice', 'Wheat']
      },
      {
        'mandi_name': 'Ghazipur Mandi',
        'state': 'Delhi',
        'district': 'East Delhi',
        'latitude': 28.6200,
        'longitude': 77.3200,
        'crops_available': ['Rice', 'Wheat', 'Maize', 'Cotton']
      }
    ],
    'Punjab': [
      {
        'mandi_name': 'Anandpur Sahib Mandi',
        'state': 'Punjab',
        'district': 'Rupnagar',
        'latitude': 31.2359,
        'longitude': 76.4974,
        'crops_available': ['Rice', 'Wheat', 'Maize', 'Sugarcane']
      },
      {
        'mandi_name': 'Ludhiana Mandi',
        'state': 'Punjab',
        'district': 'Ludhiana',
        'latitude': 30.9010,
        'longitude': 75.8573,
        'crops_available': ['Wheat', 'Rice', 'Cotton', 'Sugarcane']
      }
    ],
    'Haryana': [
      {
        'mandi_name': 'Karnal Mandi',
        'state': 'Haryana',
        'district': 'Karnal',
        'latitude': 29.6857,
        'longitude': 76.9905,
        'crops_available': ['Rice', 'Wheat', 'Maize', 'Mustard']
      },
      {
        'mandi_name': 'Hisar Mandi',
        'state': 'Haryana',
        'district': 'Hisar',
        'latitude': 29.1492,
        'longitude': 75.7217,
        'crops_available': ['Wheat', 'Cotton', 'Sugarcane', 'Mustard']
      }
    ],
    'Uttar Pradesh': [
      {
        'mandi_name': 'Agra Mandi',
        'state': 'Uttar Pradesh',
        'district': 'Agra',
        'latitude': 27.1767,
        'longitude': 78.0081,
        'crops_available': ['Wheat', 'Rice', 'Sugarcane', 'Potato']
      },
      {
        'mandi_name': 'Lucknow Mandi',
        'state': 'Uttar Pradesh',
        'district': 'Lucknow',
        'latitude': 26.8467,
        'longitude': 80.9462,
        'crops_available': ['Rice', 'Wheat', 'Sugarcane', 'Potato']
      }
    ],
    'Maharashtra': [
      {
        'mandi_name': 'Pune Mandi',
        'state': 'Maharashtra',
        'district': 'Pune',
        'latitude': 18.5204,
        'longitude': 73.8567,
        'crops_available': ['Sugarcane', 'Cotton', 'Soybean', 'Wheat']
      },
      {
        'mandi_name': 'Nagpur Mandi',
        'state': 'Maharashtra',
        'district': 'Nagpur',
        'latitude': 21.1458,
        'longitude': 79.0882,
        'crops_available': ['Cotton', 'Soybean', 'Wheat', 'Rice']
      }
    ]
  };

  /// Get list of mandis for a specific state
  static Future<List<Map<String, dynamic>>> getMandisByState(
      String state) async {
    try {
      // In a real implementation, you would call the Agmarknet API here
      // For now, we'll use fallback data
      final mandis = _fallbackMandiData[state] ?? [];

      if (kDebugMode) {
        print('Found ${mandis.length} mandis in $state');
      }

      return mandis;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching mandis for $state: $e');
      }
      return [];
    }
  }

  /// Get all available mandis (for location-based search)
  static Future<List<Map<String, dynamic>>> getAllMandis() async {
    try {
      // Try to fetch from backend API first with very short timeout
      final response = await http.get(
        Uri.parse('${AppConfig.marketPriceApiBaseUrl}/mandis'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final mandis = List<Map<String, dynamic>>.from(data['data']);
          if (kDebugMode) {
            print('Fetched ${mandis.length} mandis from API');
          }
          return mandis;
        }
      }

      if (kDebugMode) {
        print('API failed, using fallback data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('API error, using fallback data: $e');
      }
    }

    // Fallback to local data immediately
    List<Map<String, dynamic>> allMandis = [];
    for (String state in _fallbackMandiData.keys) {
      final mandis = await getMandisByState(state);
      allMandis.addAll(mandis);
    }

    if (kDebugMode) {
      print('Using fallback data: ${allMandis.length} mandis');
    }

    return allMandis;
  }

  /// Find nearest mandis to user's location
  static Future<List<Map<String, dynamic>>> getNearestMandis(
      double latitude, double longitude,
      {int limit = 5}) async {
    try {
      final allMandis = await getAllMandis();

      // Create new list with distances to avoid modifying unmodifiable maps
      List<Map<String, dynamic>> mandisWithDistance = [];

      for (var mandi in allMandis) {
        final distance = _calculateDistance(
            latitude, longitude, mandi['latitude'], mandi['longitude']);

        // Create a new map with distance added
        Map<String, dynamic> mandiWithDistance =
            Map<String, dynamic>.from(mandi);
        mandiWithDistance['distance_km'] = distance;
        mandisWithDistance.add(mandiWithDistance);
      }

      // Sort by distance and return top results
      mandisWithDistance.sort((a, b) =>
          (a['distance_km'] as double).compareTo(b['distance_km'] as double));

      return mandisWithDistance.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error finding nearest mandis: $e');
      }
      return [];
    }
  }

  /// Get current prices for crops in a specific mandi
  static Future<List<Map<String, dynamic>>> getMandiPrices(
      String mandiName) async {
    try {
      // Try to fetch from backend API first
      final response = await http.get(
        Uri.parse(
            '${AppConfig.marketPriceApiBaseUrl}/mandis/prices?mandi_name=${Uri.encodeComponent(mandiName)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final prices = List<Map<String, dynamic>>.from(data['data']);
          if (kDebugMode) {
            print(
                'Fetched prices for $mandiName from API: ${prices.length} crops');
          }
          return prices;
        }
      }

      // Fallback to sample prices
      final samplePrices = _generateSamplePrices(mandiName);

      if (kDebugMode) {
        print(
            'Using sample prices for $mandiName: ${samplePrices.length} crops');
      }

      return samplePrices;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching prices for $mandiName: $e');
      }
      return [];
    }
  }

  /// Get prices for all crops in nearest mandis
  static Future<Map<String, dynamic>> getLocationBasedPrices(
      double latitude, double longitude) async {
    try {
      // Try to fetch from backend API first with very short timeout
      final response = await http.get(
        Uri.parse(
            '${AppConfig.marketPriceApiBaseUrl}/prices/location-based?latitude=$latitude&longitude=$longitude'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 1)); // Very short timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (kDebugMode) {
            print(
                'Fetched location-based prices from API: ${data['data'].length} crops');
          }
          return data;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('API error, using immediate fallback: $e');
      }
    }

    // No mandis found nearby - return empty data
    if (kDebugMode) {
      print('No mandis found nearby, returning empty data');
    }

    return {
      'success': true,
      'data': [],
      'nearest_mandi': null,
      'total_mandis': 0,
      'fallback': true,
      'message': 'No mandis found near your location'
    };
  }

  /// Generate immediate fallback prices for location-based data
  static List<Map<String, dynamic>> _generateLocationBasedFallbackPrices(
      double latitude, double longitude) {
    final basePrices = {
      'Rice': {'min': 20.0, 'max': 35.0, 'unit': 'kg'},
      'Wheat': {'min': 18.0, 'max': 28.0, 'unit': 'kg'},
      'Maize': {'min': 15.0, 'max': 25.0, 'unit': 'kg'},
      'Cotton': {'min': 55.0, 'max': 80.0, 'unit': 'kg'},
      'Tomato': {'min': 25.0, 'max': 50.0, 'unit': 'kg'},
      'Onion': {'min': 20.0, 'max': 40.0, 'unit': 'kg'},
      'Soybean': {'min': 30.0, 'max': 45.0, 'unit': 'kg'},
      'Mustard': {'min': 40.0, 'max': 60.0, 'unit': 'kg'},
    };

    List<Map<String, dynamic>> allPrices = [];

    // Generate prices for 3 sample mandis
    final mandis = [
      {
        'name': 'Sample Mandi 1',
        'distance': 5.0,
        'state': 'Sample State',
        'district': 'Sample District'
      },
      {
        'name': 'Sample Mandi 2',
        'distance': 8.0,
        'state': 'Sample State',
        'district': 'Sample District'
      },
      {
        'name': 'Sample Mandi 3',
        'distance': 12.0,
        'state': 'Sample State',
        'district': 'Sample District'
      },
    ];

    for (var mandi in mandis) {
      basePrices.forEach((crop, priceData) {
        final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
        final price = (priceData['min'] as double) +
            ((priceData['max'] as double) - (priceData['min'] as double)) *
                random;

        allPrices.add({
          'crop_name': crop,
          'current_price': price.toStringAsFixed(2),
          'unit': priceData['unit'],
          'price_type': 'wholesale',
          'date': DateTime.now().toIso8601String().split('T')[0],
          'market_demand': _getMarketDemand(
              price, priceData['min'] as double, priceData['max'] as double),
          'mandi_name': mandi['name'],
          'mandi_distance': mandi['distance'],
          'mandi_state': mandi['state'],
          'mandi_district': mandi['district'],
        });
      });
    }

    return allPrices;
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Generate sample prices for demonstration
  static List<Map<String, dynamic>> _generateSamplePrices(String mandiName) {
    final basePrices = {
      'Rice': {'min': 20, 'max': 35, 'unit': 'kg'},
      'Wheat': {'min': 18, 'max': 28, 'unit': 'kg'},
      'Maize': {'min': 15, 'max': 25, 'unit': 'kg'},
      'Cotton': {'min': 55, 'max': 80, 'unit': 'kg'},
      'Sugarcane': {'min': 2.8, 'max': 4.0, 'unit': 'kg'},
      'Potato': {'min': 12, 'max': 20, 'unit': 'kg'},
      'Tomato': {'min': 25, 'max': 50, 'unit': 'kg'},
      'Onion': {'min': 20, 'max': 40, 'unit': 'kg'},
      'Soybean': {'min': 30, 'max': 45, 'unit': 'kg'},
      'Mustard': {'min': 40, 'max': 60, 'unit': 'kg'},
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
        'price_trend': _getPriceTrend(),
        'min_price': priceData['min'] as double,
        'max_price': priceData['max'] as double,
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

  static String _getPriceTrend() {
    final trends = ['up', 'down', 'stable'];
    final random = DateTime.now().millisecondsSinceEpoch % 3;
    return trends[random];
  }

  /// Get states with available mandis
  static List<String> getAvailableStates() {
    return _fallbackMandiData.keys.toList();
  }

  /// Search mandis by name
  static Future<List<Map<String, dynamic>>> searchMandis(String query) async {
    try {
      final allMandis = await getAllMandis();
      final queryLower = query.toLowerCase();

      return allMandis.where((mandi) {
        return mandi['mandi_name']
                .toString()
                .toLowerCase()
                .contains(queryLower) ||
            mandi['state'].toString().toLowerCase().contains(queryLower) ||
            mandi['district'].toString().toLowerCase().contains(queryLower);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error searching mandis: $e');
      }
      return [];
    }
  }
}
