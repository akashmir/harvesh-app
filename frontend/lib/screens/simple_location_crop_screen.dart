// ignore_for_file: library_private_types_in_public_api

import 'package:crop/main.dart';
import 'package:crop/services/location_service.dart';
import 'package:crop/services/regional_data_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class SimpleLocationCropScreen extends StatefulWidget {
  const SimpleLocationCropScreen({super.key});

  @override
  _SimpleLocationCropScreenState createState() =>
      _SimpleLocationCropScreenState();
}

class _SimpleLocationCropScreenState extends State<SimpleLocationCropScreen> {
  final nitrogenController = TextEditingController();
  final phosphorusController = TextEditingController();
  final potassiumController = TextEditingController();
  final temperatureController = TextEditingController();
  final humidityController = TextEditingController();
  final phController = TextEditingController();
  final rainfallController = TextEditingController();

  String recommendation = "";
  String confidence = "";
  List<Map<String, dynamic>> topPredictions = [];
  bool isLoading = false;
  bool isLocationLoading = false;
  String selectedModel = "rf";
  String locationInfo = "";
  RegionalData? regionalData;
  bool useLocationData = true;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    if (!useLocationData) return;

    setState(() {
      isLocationLoading = true;
    });

    try {
      // Get current location using geolocator
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        setState(() {
          locationInfo = "Unable to get location. Using manual input.";
          isLocationLoading = false;
        });
        return;
      }

      // Get location name
      final locationName = await LocationService.getLocationName(
          position.latitude, position.longitude);

      // Get regional data
      regionalData = await RegionalDataService.getRegionalData(
          position.latitude, position.longitude);

      setState(() {
        locationInfo = locationName;
        isLocationLoading = false;
      });

      // Auto-fill form with regional data
      if (regionalData != null) {
        _fillFormWithRegionalData(regionalData!);
      }
    } catch (e) {
      setState(() {
        locationInfo = "Error getting location: $e";
        isLocationLoading = false;
      });
    }
  }

  void _fillFormWithRegionalData(RegionalData data) {
    setState(() {
      nitrogenController.text = data.nitrogen.toStringAsFixed(1);
      phosphorusController.text = data.phosphorus.toStringAsFixed(1);
      potassiumController.text = data.potassium.toStringAsFixed(1);
      temperatureController.text = data.temperature.toStringAsFixed(1);
      humidityController.text = data.humidity.toStringAsFixed(1);
      phController.text = data.ph.toStringAsFixed(1);
      rainfallController.text = data.rainfall.toStringAsFixed(1);
    });
  }

  Future<void> getRecommendation() async {
    if (nitrogenController.text.isEmpty ||
        phosphorusController.text.isEmpty ||
        potassiumController.text.isEmpty ||
        temperatureController.text.isEmpty ||
        humidityController.text.isEmpty ||
        phController.text.isEmpty ||
        rainfallController.text.isEmpty) {
      setState(() {
        recommendation = "Please fill in all fields";
      });
      return;
    }

    setState(() {
      isLoading = true;
      recommendation = "";
      confidence = "";
      topPredictions = [];
    });

    try {
      // Validate API configuration
      if (!AppConfig.isCropApiUrlValid) {
        setState(() {
          recommendation =
              "Crop API URL not configured. Please check environment variables.";
        });
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.cropApiBaseUrl}/recommend'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'N': double.parse(nitrogenController.text),
          'P': double.parse(phosphorusController.text),
          'K': double.parse(potassiumController.text),
          'temperature': double.parse(temperatureController.text),
          'humidity': double.parse(humidityController.text),
          'ph': double.parse(phController.text),
          'rainfall': double.parse(rainfallController.text),
          'model_type': selectedModel,
        }),
      );

      if (response.statusCode == 200) {
        final recommendationData = jsonDecode(response.body);
        setState(() {
          recommendation = recommendationData['recommended_crop'];
          confidence =
              (recommendationData['confidence'] * 100).toStringAsFixed(1);
          topPredictions = List<Map<String, dynamic>>.from(
              recommendationData['top_3_predictions']);
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          recommendation = "Error: ${errorData['error']}";
        });
      }
    } catch (e) {
      setState(() {
        recommendation = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleRadioValueChange(String? value) {
    setState(() {
      selectedModel = value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Crop Recommendation'),
        centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainApp()),
            );
          },
        ),
        actions: [
          IconButton(
            icon:
                Icon(useLocationData ? Icons.location_on : Icons.location_off),
            onPressed: () {
              setState(() {
                useLocationData = !useLocationData;
              });
              if (useLocationData) {
                _loadLocationData();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Status Card
              Card(
                color: useLocationData
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            useLocationData
                                ? Icons.location_on
                                : Icons.location_off,
                            color: useLocationData ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            useLocationData
                                ? 'Location-Based Data'
                                : 'Manual Input',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  useLocationData ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isLocationLoading)
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Getting location data...'),
                          ],
                        )
                      else
                        Text(
                          locationInfo.isNotEmpty
                              ? locationInfo
                              : 'Tap location icon to enable',
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (regionalData != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Region: ${regionalData!.region} | Climate: ${regionalData!.temperature.toStringAsFixed(1)}°C',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Model Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select AI Model:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            // ignore: deprecated_member_use
                            child: RadioListTile<String>(
                              title: const Text('Random Forest'),
                              subtitle: const Text('99.55% accuracy'),
                              value: 'rf',
                              groupValue: selectedModel,
                              onChanged: _handleRadioValueChange,
                            ),
                          ),
                          Expanded(
                            // ignore: deprecated_member_use
                            child: RadioListTile<String>(
                              title: const Text('Neural Network'),
                              subtitle: const Text('98.86% accuracy'),
                              value: 'nn',
                              groupValue: selectedModel,
                              onChanged: _handleRadioValueChange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Input Fields
              buildTextField("Nitrogen (N) - kg/ha", nitrogenController),
              buildTextField("Phosphorus (P) - kg/ha", phosphorusController),
              buildTextField("Potassium (K) - kg/ha", potassiumController),
              buildTextField("Temperature (°C)", temperatureController),
              buildTextField("Humidity (%)", humidityController),
              buildTextField("Soil pH", phController),
              buildTextField("Rainfall (mm)", rainfallController),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: useLocationData ? _loadLocationData : null,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : getRecommendation,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.psychology),
                      label: Text(
                          isLoading ? 'Analyzing...' : 'Get Recommendation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Results Section
              if (recommendation.isNotEmpty) ...[
                Card(
                  color: recommendation.contains("Error") ||
                          recommendation.contains("Failed")
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Recommendation:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: recommendation.contains("Error") ||
                                    recommendation.contains("Failed")
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          recommendation,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: recommendation.contains("Error") ||
                                    recommendation.contains("Failed")
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        if (confidence.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Confidence: $confidence%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (regionalData != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Based on ${regionalData!.region} climate data',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Top 3 Predictions
                if (topPredictions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Top 3 Crop Options:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ...topPredictions.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> prediction = entry.value;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${index + 1}. ${prediction['crop']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    '${(prediction['confidence'] * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: index == 0
                                          ? Colors.green
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else ...[
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.agriculture,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        useLocationData
                            ? "Getting location data...\nEnter soil parameters and get AI recommendations"
                            : "Enter soil parameters and get AI recommendations",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: useLocationData && regionalData != null
              ? const Icon(Icons.location_on, color: Colors.green)
              : null,
        ),
      ),
    );
  }
}
