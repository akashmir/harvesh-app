import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Service for handling location permissions and GPS coordinates
class LocationService {
  static const Duration _timeout = Duration(seconds: 10);

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location service: $e');
      }
      return false;
    }
  }

  /// Check location permission status
  static Future<LocationPermission> checkLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location permission: $e');
      }
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    try {
      // First check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('Location services are disabled');
        }
        return LocationPermission.denied;
      }

      // Check current permission status
      LocationPermission permission = await checkLocationPermission();

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('Location permission denied');
          }
          return permission;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('Location permission denied forever');
        }
        return permission;
      }

      return permission;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting location permission: $e');
      }
      return LocationPermission.denied;
    }
  }

  /// Get current location with permission handling
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check and request permission
      final permission = await requestLocationPermission();

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (kDebugMode) {
          print('Location permission not granted: $permission');
        }
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _timeout,
      );

      if (kDebugMode) {
        print('Location obtained: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
      return null;
    }
  }

  /// Get location with fallback to last known location
  static Future<Position?> getLocationWithFallback() async {
    try {
      // Try to get current location first
      final currentLocation = await getCurrentLocation();
      if (currentLocation != null) {
        return currentLocation;
      }

      // Fallback to last known location
      final lastKnownLocation = await Geolocator.getLastKnownPosition();
      if (lastKnownLocation != null) {
        if (kDebugMode) {
          print(
              'Using last known location: ${lastKnownLocation.latitude}, ${lastKnownLocation.longitude}');
        }
        return lastKnownLocation;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location with fallback: $e');
      }
      return null;
    }
  }

  /// Get location status for debugging
  static Future<Map<String, dynamic>> getLocationStatus() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      final permission = await checkLocationPermission();
      final currentLocation = await getCurrentLocation();
      final lastKnownLocation = await Geolocator.getLastKnownPosition();

      return {
        'service_enabled': serviceEnabled,
        'permission': permission.toString(),
        'has_current_location': currentLocation != null,
        'has_last_known_location': lastKnownLocation != null,
        'current_latitude': currentLocation?.latitude,
        'current_longitude': currentLocation?.longitude,
        'last_known_latitude': lastKnownLocation?.latitude,
        'last_known_longitude': lastKnownLocation?.longitude,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'service_enabled': false,
        'permission': 'unknown',
        'has_current_location': false,
        'has_last_known_location': false,
      };
    }
  }

  /// Open location settings if permission is denied forever
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      if (kDebugMode) {
        print('Error opening location settings: $e');
      }
      return false;
    }
  }

  /// Open app settings if permission is denied forever
  static Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        print('Error opening app settings: $e');
      }
      return false;
    }
  }

  /// Get distance between two coordinates in kilometers
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Check if location is within a certain radius
  static bool isWithinRadius(
      double lat1, double lon1, double lat2, double lon2, double radiusKm) {
    final distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= radiusKm;
  }

  /// Get location name from coordinates (reverse geocoding)
  static Future<String> getLocationName(
      double latitude, double longitude) async {
    try {
      // For now, return a simple location name
      // In a real app, you would use reverse geocoding
      return 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location name: $e');
      }
      return 'Unknown Location';
    }
  }
}
