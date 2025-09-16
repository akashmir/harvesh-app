// ignore_for_file: library_private_types_in_public_api

import 'package:crop/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({super.key});

  @override
  _CropRecommendationScreenState createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
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
  String selectedModel = "rf"; // Default to Random Forest

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
        title: const Text('Crop Recommendation System'),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Model:',
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
                              value: 'rf',
                              groupValue: selectedModel,
                              onChanged: _handleRadioValueChange,
                            ),
                          ),
                          Expanded(
                            // ignore: deprecated_member_use
                            child: RadioListTile<String>(
                              title: const Text('Neural Network'),
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
              buildTextField("Nitrogen (N)", nitrogenController),
              buildTextField("Phosphorus (P)", phosphorusController),
              buildTextField("Potassium (K)", potassiumController),
              buildTextField("Temperature (°C)", temperatureController),
              buildTextField("Humidity (%)", humidityController),
              buildTextField("pH", phController),
              buildTextField("Rainfall (mm)", rainfallController),

              const SizedBox(height: 20),

              // Get Recommendation Button
              Center(
                child: ElevatedButton(
                  onPressed: isLoading ? null : getRecommendation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: isLoading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Getting Recommendation...'),
                          ],
                        )
                      : const Text('Get Recommendation',
                          style: TextStyle(fontSize: 16)),
                ),
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
                          'Recommendation Result:',
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
                            'Top 3 Predictions:',
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
                  child: Text(
                    "Enter data and click 'Get Recommendation'",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}
