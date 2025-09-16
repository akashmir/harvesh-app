import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:crop/firebase_options.dart';
import 'package:crop/services/weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully!');

  runApp(const WeatherTestApp());
}

class WeatherTestApp extends StatelessWidget {
  const WeatherTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Service Test',
      home: const WeatherTestScreen(),
    );
  }
}

class WeatherTestScreen extends StatefulWidget {
  const WeatherTestScreen({super.key});

  @override
  State<WeatherTestScreen> createState() => _WeatherTestScreenState();
}

class _WeatherTestScreenState extends State<WeatherTestScreen> {
  final _locationController = TextEditingController(text: 'Mumbai');
  String _status = 'Ready to test weather service';
  bool _isLoading = false;
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _serviceStatus;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _testWeatherService() async {
    if (_locationController.text.isEmpty) {
      setState(() {
        _status = 'Please enter a location';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Testing weather service...';
      _weatherData = null;
    });

    try {
      // Test service status first
      final status = await WeatherService.getWeatherServiceStatus();
      setState(() {
        _serviceStatus = status;
      });

      // Test weather data
      final response = await WeatherService.getCurrentWeather(
          _locationController.text.trim());

      setState(() {
        _weatherData = response;
        _status = response['success']
            ? 'Weather data loaded successfully!'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Service Test'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weather Service Test Tool',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Mumbai, Delhi, Bangalore, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testWeatherService,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Weather Service'),
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
                    'Service Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_serviceStatus != null) ...[
                    Text(
                        'Backend Available: ${_serviceStatus!['backend_available']}'),
                    Text(
                        'Direct API Available: ${_serviceStatus!['direct_api_available']}'),
                    Text('API Key Valid: ${_serviceStatus!['api_key_valid']}'),
                    Text(
                        'Fallback Available: ${_serviceStatus!['fallback_available']}'),
                    if (_serviceStatus!['backend_error'] != null)
                      Text(
                          'Backend Error: ${_serviceStatus!['backend_error']}'),
                  ] else
                    const Text('Not tested yet'),
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
                    'Test Result:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_status),
                  if (_weatherData != null) ...[
                    const SizedBox(height: 8),
                    const Text('Weather Data:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Success: ${_weatherData!['success']}'),
                    if (_weatherData!['data'] != null) ...[
                      Text(
                          'Temperature: ${_weatherData!['data']['temperature']}°C'),
                      Text('Humidity: ${_weatherData!['data']['humidity']}%'),
                      Text(
                          'Description: ${_weatherData!['data']['description']}'),
                      Text('Location: ${_weatherData!['data']['location']}'),
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
            const Text('1. Enter a city name (e.g., Mumbai, Delhi, Bangalore)'),
            const Text('2. Tap "Test Weather Service"'),
            const Text('3. Check the service status and weather data'),
            const Text(
                '4. If backend is unavailable, it will use direct OpenWeatherMap API'),
            const Text('5. If both fail, it will show fallback data'),
          ],
        ),
      ),
    );
  }
}
