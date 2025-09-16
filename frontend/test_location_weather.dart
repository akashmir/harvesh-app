import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:crop/firebase_options.dart';
import 'package:crop/services/location_service.dart';
import 'package:crop/services/weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully!');

  runApp(const LocationWeatherTestApp());
}

class LocationWeatherTestApp extends StatelessWidget {
  const LocationWeatherTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Weather Test',
      home: const LocationWeatherTestScreen(),
    );
  }
}

class LocationWeatherTestScreen extends StatefulWidget {
  const LocationWeatherTestScreen({super.key});

  @override
  State<LocationWeatherTestScreen> createState() =>
      _LocationWeatherTestScreenState();
}

class _LocationWeatherTestScreenState extends State<LocationWeatherTestScreen> {
  String _status = 'Ready to test location-based weather';
  bool _isLoading = false;
  Map<String, dynamic>? _locationStatus;
  Map<String, dynamic>? _weatherData;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking location status...';
    });

    try {
      final status = await LocationService.getLocationStatus();
      setState(() {
        _locationStatus = status;
        _isLoading = false;
        _status = 'Location status checked';
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testLocationWeather() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing location-based weather...';
      _weatherData = null;
    });

    try {
      // Test automatic weather detection
      final response = await WeatherService.getCurrentWeatherAuto();

      setState(() {
        _weatherData = response;
        _status = response['success']
            ? 'Location-based weather loaded successfully!'
            : 'Failed to load weather: ${response['error']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _status = 'Requesting location permission...';
    });

    try {
      final permission = await LocationService.requestLocationPermission();
      setState(() {
        _status = 'Permission result: $permission';
        _isLoading = false;
      });

      // Refresh location status
      await _checkLocationStatus();
    } catch (e) {
      setState(() {
        _status = 'Error requesting permission: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openLocationSettings() async {
    try {
      final opened = await LocationService.openLocationSettings();
      setState(() {
        _status =
            opened ? 'Location settings opened' : 'Failed to open settings';
      });
    } catch (e) {
      setState(() {
        _status = 'Error opening settings: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Weather Test'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Location-Based Weather Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testLocationWeather,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Location Weather'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _requestLocationPermission,
              child: const Text('Request Location Permission'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _openLocationSettings,
              child: const Text('Open Location Settings'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_locationStatus != null) ...[
                    Text(
                        'Service Enabled: ${_locationStatus!['service_enabled']}'),
                    Text('Permission: ${_locationStatus!['permission']}'),
                    Text(
                        'Has Current Location: ${_locationStatus!['has_current_location']}'),
                    Text(
                        'Has Last Known: ${_locationStatus!['has_last_known_location']}'),
                    if (_locationStatus!['current_latitude'] != null)
                      Text(
                          'Current: ${_locationStatus!['current_latitude']}, ${_locationStatus!['current_longitude']}'),
                    if (_locationStatus!['last_known_latitude'] != null)
                      Text(
                          'Last Known: ${_locationStatus!['last_known_latitude']}, ${_locationStatus!['last_known_longitude']}'),
                    if (_locationStatus!['error'] != null)
                      Text('Error: ${_locationStatus!['error']}',
                          style: const TextStyle(color: Colors.red)),
                  ] else
                    const Text('Not checked yet'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weather Data:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_status),
                  if (_weatherData != null) ...[
                    const SizedBox(height: 8),
                    Text('Success: ${_weatherData!['success']}'),
                    if (_weatherData!['data'] != null) ...[
                      Text('Location: ${_weatherData!['data']['location']}'),
                      Text(
                          'Temperature: ${_weatherData!['data']['temperature']}°C'),
                      Text('Humidity: ${_weatherData!['data']['humidity']}%'),
                      Text(
                          'Description: ${_weatherData!['data']['description']}'),
                      if (_weatherData!['data']['latitude'] != null)
                        Text(
                            'Coordinates: ${_weatherData!['data']['latitude']}, ${_weatherData!['data']['longitude']}'),
                      if (_weatherData!['data']['is_fallback'] == true)
                        const Text('⚠️ Using fallback data',
                            style: TextStyle(color: Colors.orange)),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('1. Tap "Request Location Permission" if needed'),
            const Text(
                '2. Tap "Test Location Weather" to get weather for your location'),
            const Text('3. Check the location status and weather data'),
            const Text(
                '4. If permission is denied, tap "Open Location Settings"'),
          ],
        ),
      ),
    );
  }
}
